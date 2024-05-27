from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
import re

import sys
import codecs
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

app = Flask(__name__)

#todo function target
# 縣市(台北市+XX區)
# 房屋類型(整層住家、獨立套房、分租套房)
# 租金
# 格局(1、2、3、4房)
# 坪數(10、)
# 房屋型態(別墅、公寓、電梯大樓、透天)

#todo connect to database
# gh_members
mydb = mysql.connector.connect(
    host="localhost",
    user="root",
    password="123456",
    database="gh_members"
)

cursor = mydb.cursor()

#todo create table
# members table
cursor.execute("USE gh_members")
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
             
# new_housedetail table
cursor.execute("USE ghdetail")
cursor.execute('''
    CREATE TABLE IF NOT EXISTS new_housedetail (
        hid VARCHAR(255) NOT NULL PRIMARY KEY,
        url VARCHAR(255) NOT NULL,
        title VARCHAR(255) NOT NULL,
        pattern VARCHAR(255) NOT NULL,
        size VARCHAR(255) NOT NULL,
        layer VARCHAR(255) NOT NULL,
        type VARCHAR(255) NOT NULL,
        price INT NOT NULL, 
        deposit VARCHAR(255) NOT NULL, 
        address VARCHAR(255) NOT NULL, 
        subway TEXT, 
        bus TEXT,
        agency_id INT, 
        agency VARCHAR(255), 
        agency_company VARCHAR(255), 
        content TEXT, 
        name VARCHAR(255), 
        text VARCHAR(255)
    )
''')

#todo 函數
def is_valid_chinese_name(name):
    return bool(re.fullmatch(r'[\u4e00-\u9fff]+', name))

def is_valid_email(gmail):
    return bool(re.fullmatch(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', gmail))

def is_valid_phone(phone):
    return bool(re.fullmatch(r'\d+', phone))

def is_valid_password(password):
    return bool(re.fullmatch(r'[A-Za-z0-9]{1,16}', password))

#todo 使用者註冊
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
    cursor.execute("USE gh_members")
    cursor.execute("SELECT gmail FROM members WHERE gmail = %s", (gmail,))
    existing_account = cursor.fetchone()
    if existing_account:
        return jsonify({'error': 'User already exists'}), 409  # HTTP 409 Conflict
    
    # 將密碼進行哈希加密
    hashed_password = generate_password_hash(password)
    
    # 將用戶帳號和加密後的密碼寫入資料庫
    cursor.execute("INSERT INTO members (gender, password, username, phone, gmail) VALUES (%s, %s, %s, %s, %s)", (gender, hashed_password, username, phone, gmail))
    mydb.commit()
    return jsonify({'message': 'User registered successfully'}), 200

#todo 使用者登入
@app.route('/login', methods=['POST'])
def login():
    data = request.json  # 從請求主體中解析 JSON 資料
    gmail = data['gmail']
    password = data['password']
    
    # 從資料庫中獲取用戶的加密後的密碼
    cursor = mydb.cursor()
    cursor.execute("USE gh_members")
    cursor.execute("SELECT password FROM members WHERE gmail = %s", (gmail,))
    user = cursor.fetchone()
    
    if user:
        if check_password_hash(user[0], password):
            return jsonify({'message':'Login successful'}), 200
        else:
            return jsonify({'error':'wrong password'}), 400
    else:
        return jsonify({'error':'User does not exists'}), 404

#todo 顯示所有會員
@app.route('/members', methods=["GET"])
def all_member():
    cursor = mydb.cursor()
    cursor.execute("USE gh_members")
    cursor.execute("SELECT member_id, username, phone, gmail, gender FROM members")
    members = cursor.fetchall()
    members_list = [{'id':member[0],'username': member[1], 'phone': member[2], 'gmail':member[3], 'gender':member[4]} for member in members]
    return jsonify(members_list), 200

#todo 更改密碼
@app.route('/change_password', methods=['POST'])
def change_password():
    data = request.get_json()
    gmail = data['gmail']
    old_password = data['old_password']
    new_password = data['new_password']

    cursor = mydb.cursor()
    cursor.execute("USE gh_members")
    cursor.execute("SELECT password FROM members WHERE gmail = %s", (gmail,))
    user = cursor.fetchone()

    if user:
        if check_password_hash(user[0], old_password):
            cursor.execute("UPDATE members SET password = %s WHERE gmail = %s", (generate_password_hash(new_password), gmail))
            mydb.commit()
            return jsonify({'message': 'Password updated successfully'}), 200
        else:
            return jsonify({'error':'wrong password'}), 400
    else:
        return jsonify({'error':'User does not exists'}), 404

#todo search test
@app.route('/search_test', methods=['POST'])
def search_houses_test():
    data = request.get_json()  # 获取 JSON 请求体
    if data:
        for attribute, value in data.items():
            if value:
                print(f"'{attribute}':'{value}'")
        return jsonify({'message': 'Data received and printed'}), 200
    else:
        return jsonify({'error': 'No data received'}), 400 

#todo 搜尋房屋物件
@app.route('/search', methods=['POST'])
def search_houses():
    filters = request.json
    query = "SELECT * FROM new_housedetail WHERE 1=1"
    params = []
    
    if filters.get('city'): #* String 城市
        pass

    if filters.get('district'): #* String 地區
        query += " AND address LIKE %s"
        params.append(filters['district'] + '%')

    if filters.get('room_type'): #* [int, int] 房屋類型
        room_type = filters.get('room_type')
        if room_type == "獨立套房" or room_type == "雅房" or room_type == "分租套房":
            query += " AND pattern = %s"
            params.append(room_type)
        elif room_type == "整層住家":
            query += " AND (pattern = %s OR pattern LIKE %s) AND pattern NOT IN ('獨立套房', '分租套房', '雅房') "
            params.append('整層住家')
            params.append('%'+'房'+'%')
            
    if filters.get('rental_range'): #* [int, int] 租金
        rental_range = filters['rental_range']
        if rental_range[0] != -1:
            query += " AND price >= %s"
            params.append(rental_range[0])
        if rental_range[1] != -1:
            query += " AND price <= %s"
            params.append(rental_range[1])

    if filters.get('room_count'): #* String 房數
        room_count = filters.get('room_count')
        if room_count == 4:
            query += " AND CAST(SUBSTRING_INDEX(pattern, '房', 1) AS UNSIGNED) >= %s"
            params.append(room_count)
        else:
            query += " AND CAST(SUBSTRING_INDEX(pattern, '房', 1) AS UNSIGNED) = %s"
            params.append(room_count)

    if filters.get('house_size'): #* [int, int] 坪數
        house_size = filters['house_size']
        if house_size[0] != -1:
            query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS DECIMAL(5,2)) >= %s"
            params.append(house_size[0])
        if house_size[1] != -1:
            query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS DECIMAL(5,2)) <= %s"
            params.append(house_size[1])

    if filters.get('house_type'): #* String 房型
        query += " AND type = %s"
        params.append(filters['house_type'])

    if filters.get('other_options'): #* String 其他
        pass
    
    cursor = mydb.cursor()
    cursor.execute("USE ghdetail")
    cursor.execute(query, params)
    results = cursor.fetchall()
    
    data = [{
        'hid':result[0],
        'url': result[1],
        'title': result[2],
        'pattern':result[3],
        'size':result[4],
        'layer':result[5],
        'type':result[6],
        'price':result[7],
        'deposit':result[8],
        'address':result[9],
        'subway':result[10],
        'bus':result[11]
    } for result in results]

    return jsonify(data), 200

#todo 
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)