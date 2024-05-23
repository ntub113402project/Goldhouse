from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
import re

app = Flask(__name__)

# 設定 MySQL 連線
mydb = mysql.connector.connect(
    host="localhost",
    user="root",
    password="ntubGH113402",
    database="gh_members"
)

cursor = mydb.cursor()

# 創建名為 image 的表格
cursor.execute('''
    CREATE TABLE IF NOT EXISTS members (
        member_id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        gmail VARCHAR(255) NOT NULL,
        gender ENUM('1','2') NOT NULL,
        phone VARCHAR(16) NOT NULL,
        password VARCHAR(255) NOT NULL
    )
''')

def is_valid_chinese_name(name):
    return bool(re.fullmatch(r'[\u4e00-\u9fff]+', name))

def is_valid_email(gmail):
    return bool(re.fullmatch(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', gmail))

def is_valid_phone(phone):
    return bool(re.fullmatch(r'\d+', phone))

def is_valid_password(password):
    return bool(re.fullmatch(r'[A-Za-z0-9]{1,16}', password))

# API 端點，處理用戶註冊請求
@app.route('/register', methods=['POST'])
def register():
    data = request.json  # 從請求主體中解析 JSON 資料
    username = data['username']
    password = data['password']
    phone = data['phone']
    gmail = data['gmail']
    gender = data['gender']

    # 處理 empty field
    if any(key == "" for key in [username, password, phone, gender, gmail]):
        return jsonify({'error': '所有欄位不能為空'}), 400

    # 處理 invalid register
    if not is_valid_chinese_name(username):
        return jsonify({'error': '姓名請輸入中文'}), 422
    if not is_valid_email(gmail):
        return jsonify({'error': '電子郵件格式錯誤'}), 422
    if not is_valid_phone(phone):
        return jsonify({'error': '手機號碼格式錯誤，請輸入數字'}), 422
    if not is_valid_password(password):
        return jsonify({'error': '密碼限制為16個字以內，並且只能輸入英文字母及數字'}), 422

    # 處理重複註冊
    cursor = mydb.cursor()
    cursor.execute("SELECT gmail, phone FROM members WHERE gmail = %s OR phone = %s", (gmail, phone))
    existing_account = cursor.fetchone()
    if existing_account:
        if existing_account[0] == gmail and existing_account[1] == phone:
            return jsonify({'error': '此電子郵件及手機號碼已被註冊'}),409
        elif existing_account[0] == gmail:
            return jsonify({'error': '電子郵件已被註冊'}),409
        else:
            return jsonify({'error': '手機號碼已被註冊'}),409
    
    # 將密碼進行哈希加密
    hashed_password = generate_password_hash(password)
    
    # 將用戶帳號和加密後的密碼寫入資料庫
    cursor.execute("INSERT INTO members (gender, password, username, phone, gmail) VALUES (%s, %s, %s, %s, %s)", (gender, hashed_password, username, phone, gmail))
    mydb.commit()
    return jsonify({'message': 'User registered successfully'}), 200

# API 端點，處理用戶登入請求
@app.route('/login', methods=['POST'])
def login():
    data = request.json  # 從請求主體中解析 JSON 資料
    gmail = data['gmail']
    password = data['password']
    
    # 從資料庫中獲取用戶的加密後的密碼
    cursor = mydb.cursor()
    cursor.execute("SELECT password FROM members WHERE gmail = %s", (gmail,))
    user = cursor.fetchone()

    if any(key == "" for key in [password, gmail]):
        return jsonify({'error': '所有欄位不能為空'}), 400
    
    if user:
        if check_password_hash(user[0], password):
            return jsonify({'message':'登入成功'}), 200
        else:
            return jsonify({'error':'密碼輸入錯誤'}), 400
    else:
        return jsonify({'error':'電子郵件不存在'}), 404

@app.route('/members', methods=["GET"])
def all_member():
    cursor = mydb.cursor()
    cursor.execute("SELECT member_id, username, phone, gmail, gender FROM members")
    members = cursor.fetchall()
    members_list = [{'id':member[0],'username': member[1], 'phone': member[2], 'gmail':member[3], 'gender':member[4]} for member in members]
    return jsonify(members_list), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)