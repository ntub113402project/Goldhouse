from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
import re

app = Flask(__name__)

# 設定 MySQL 連線
mydb = mysql.connector.connect(
    host="localhost",
    user="root",
    password="123456",
    database="ghdetail"
)

cursor = mydb.cursor()

# 創建名為 image 的表格
cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
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
        return jsonify({'error': 'ALL field cannot be empty'}), 400

    # 處理 invalid register
    if not is_valid_chinese_name(username):
        return jsonify({'error': 'Invalid name. Only Chinese characters are allowed.'}), 422
    if not is_valid_email(gmail):
        return jsonify({'error': 'Invalid gmail format.'}), 422
    if not is_valid_phone(phone):
        return jsonify({'error': 'Invalid phone number. Only digits are allowed.'}), 422
    if not is_valid_password(password):
        return jsonify({'error': 'Invalid password. Password must be 16 characters long and contain only letters and digits.'}), 422

    # 處理重複註冊
    cursor = mydb.cursor()
    cursor.execute("SELECT gmail FROM users WHERE gmail = %s", (gmail,))
    existing_account = cursor.fetchone()
    if existing_account:
        return jsonify({'error': 'User already exists'}), 409  # HTTP 409 Conflict
    
    # 將密碼進行哈希加密
    hashed_password = generate_password_hash(password)
    
    # 將用戶帳號和加密後的密碼寫入資料庫
    cursor.execute("INSERT INTO users (gender, password, username, phone, gmail) VALUES (%s, %s, %s, %s, %s)", (gender, hashed_password, username, phone, gmail))
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
    cursor.execute("SELECT password FROM users WHERE gmail = %s", (gmail,))
    user = cursor.fetchone()
    
    if user:
        if check_password_hash(user[0], password):
            return jsonify({'message':'Login successful'}), 200
        else:
            return jsonify({'error':'wrong password'}), 400
    else:
        return jsonify({'error':'User does not exists'}), 404

@app.route('/members', methods=["GET"])
def all_member():
    cursor = mydb.cursor()
    cursor.execute("SELECT member_id, username, phone, gmail, gender FROM users")
    members = cursor.fetchall()
    members_list = [{'id':member[0],'username': member[1], 'phone': member[2], 'gmail':member[3], 'gender':member[4]} for member in members]
    return jsonify(members_list), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)