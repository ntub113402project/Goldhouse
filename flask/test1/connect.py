from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector

app = Flask(__name__)

# 設定 MySQL 連線
mydb = mysql.connector.connect(
    host="localhost",
    user="root",
    password="123456",
    database="ghdetail"
)

cursor = mydb.cursor()

# 使用 ghdetail 資料庫
# cursor.execute('USE ghdetail')

# 清空 image 表格
# cursor.execute('TRUNCATE TABLE user')

# 創建名為 image 的表格
cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(16),
        account VARCHAR(255) NOT NULL,
        password VARCHAR(255) NOT NULL,
        gmail VARCHAR(255)
    )
''')

# API 端點，處理用戶註冊請求
@app.route('/register', methods=['POST'])
def register():
    data = request.json  # 從請求主體中解析 JSON 資料
    name = data['name']
    password = data['password']
    account = data['account']
    phone = data['phone']
    gmail = data['gmail']

    if any(key == "" for key in [name, password, account]):
        return jsonify({'error': 'Invalid register'}), 400

    cursor = mydb.cursor()
    cursor.execute("SELECT account FROM users WHERE account = %s", (account,))
    existing_account = cursor.fetchone()
    if existing_account:
        return jsonify({'error': 'Account already exists'}), 409  # HTTP 409 Conflict
    
    # 將密碼進行哈希加密
    hashed_password = generate_password_hash(password)
    
    # 將用戶帳號和加密後的密碼寫入資料庫
    cursor.execute("INSERT INTO users (account, password, name, phone, gmail) VALUES (%s, %s, %s, %s, %s)", (account, hashed_password, name, phone, gmail))
    mydb.commit()
    
    return jsonify({'message': 'User registered successfully'}), 200

# API 端點，處理用戶登入請求
@app.route('/login', methods=['POST'])
def login():
    data = request.json  # 從請求主體中解析 JSON 資料
    account = data['account']
    password = data['password']
    
    # 從資料庫中獲取用戶的加密後的密碼
    cursor = mydb.cursor()
    cursor.execute("SELECT password FROM users WHERE account = %s", (account,))
    user = cursor.fetchone()
    
    if user:
        if check_password_hash(user[0], password):
            return jsonify({'message':'Login successful'}), 200
        else:
            return jsonify({'message':'user {account} wrong password'}), 400
    else:
        return jsonify({'message':'user {account} does not exists'}), 404

@app.route('/members', methods=["GET"])
def all_member():
    cursor = mydb.cursor()
    result = cursor.execute("SELECT * FROM users")
    members = cursor.fetchall()
    members_list = [{'id':member[0],'account': member[3], 'name': member[1], 'phone': member[2], 'gmail':member[5]} for member in members]
    return jsonify(members_list), 200

if __name__ == '__main__':
    app.run(debug=True)
