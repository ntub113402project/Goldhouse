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
# 連接到 gh_members 資料庫
db_gh_members = mysql.connector.connect(
    host="localhost",
    user="root",
    password="ntubGH113402",
    database="gh_members"
)
cursor_members = db_gh_members.cursor()

# 連接到 ghdetail 資料庫
db_ghdetail = mysql.connector.connect(
    host="localhost",
    user="root",
    password="ntubGH113402",
    database="ghdetail"
)
cursor_detail = db_ghdetail.cursor()

# 創建 members 表
cursor_members.execute('''
    CREATE TABLE IF NOT EXISTS members (
        member_id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        gmail VARCHAR(255) NOT NULL,
        gender ENUM('1','2') NOT NULL,
        phone VARCHAR(16) NOT NULL,
        password VARCHAR(255) NOT NULL
    )
''')

# 創建 new_housedetail 表
cursor_detail.execute('''
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
    cursor_members.execute("USE gh_members")
    cursor_members.execute("SELECT gmail, phone FROM members WHERE gmail = %s OR phone = %s", (gmail, phone))
    existing_account = cursor_members.fetchone()
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
    cursor_members.execute("INSERT INTO members (gender, password, username, phone, gmail) VALUES (%s, %s, %s, %s, %s)", (gender, hashed_password, username, phone, gmail))
    db_gh_members.commit()
    return jsonify({'message': 'User registered successfully'}), 200

#todo 使用者登入
@app.route('/login', methods=['POST'])
def login():
    data = request.json  # 從請求主體中解析 JSON 資料
    gmail = data['gmail']
    password = data['password']
    
    # 從資料庫中獲取用戶的加密後的密碼
    cursor = db_gh_members.cursor()
    cursor.execute("USE gh_members")
    cursor.execute("SELECT member_id, username, phone, gender, password FROM members WHERE gmail = %s", (gmail,))
    members = cursor.fetchone()

    if any(key == "" for key in [password, gmail]):
        return jsonify({'error': '所有欄位不能為空'}), 400
    
    if members:
        if check_password_hash(members[4], password):
            memberlist = {
                'member_id': members[0],
                'username': members[1],
                'phone': members[2],
                'gmail': gmail,
                'gender': members[3]
            }
            print(memberlist)  
            return jsonify({'message': '登入成功', 'members': memberlist}), 200
        else:
            return jsonify({'error': '密碼輸入錯誤'}), 400
    else:
        return jsonify({'error': '電子郵件不存在'}), 404

#todo 顯示所有會員
@app.route('/members', methods=["GET"])
def all_member():
    cursor = db_gh_members.cursor()
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

    cursor = db_gh_members.cursor()
    cursor.execute("USE gh_members")
    cursor.execute("SELECT password FROM members WHERE gmail = %s", (gmail,))
    user = cursor.fetchone()

    if user:
        if check_password_hash(user[0], old_password):
            cursor.execute("UPDATE members SET password = %s WHERE gmail = %s", (generate_password_hash(new_password), gmail))
            db_gh_members.commit()
            return jsonify({'message': '密碼修改成功'}), 200
        else:
            return jsonify({'error':'舊密碼錯誤'}), 400
    else:
        return jsonify({'error':'用戶不存在'}), 404

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
        
        if room_type == "獨立套房" or "雅房" or "分租套房":
            query += " AND pattern = %s"
            params.append(filters['room_type'])
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
            query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS UNSIGNED) >= %s"
            params.append(house_size[0])
        if house_size[1] != -1:
            query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS UNSIGNED) <= %s"
            params.append(house_size[1])

    if filters.get('house_type'): #* String 房型
        query += " AND type = %s"
        params.append(filters['house_type'])

    if filters.get('other_options'): #* String 其他
        pass
    
    cursor = db_ghdetail.cursor()
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

    print(f"{query}\n\n{params}")
    print(data)

    return jsonify(data), 200

#todo 
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)