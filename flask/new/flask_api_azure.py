from datetime import datetime,timedelta
import json
import uuid
from flask import Flask, request, jsonify, send_from_directory
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
from base64 import b64encode
import re
from flask_cors import CORS
import os
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import random
import string

import sys
import codecs

from werkzeug.utils import secure_filename
sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

app = Flask(__name__)
CORS(app)

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

verification_codes = {}

@app.route('/forget_password',methods=['POST'])
def forget_password():
    data = request.json
    gmail = data['gmail']

    cursor = db_gh_members.cursor()
    cursor.execute("Select gmail FROM members WHERE gmail =%s", (gmail,))
    existing_account = cursor.fetchone()

    if existing_account:
        code = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
        expiry_time = datetime.now() + timedelta(minutes=10)
        verification_codes[gmail] = {'code': code, 'expires': expiry_time}

        from_email = "cthwjccl@gmail.com"
        from_password = "zkad gluq acno cxph"
        subject = "您的驗證碼"
        body = f"您的驗證碼是: {code}. 此驗證碼在10分鐘內有效。"

        msg = MIMEMultipart()
        msg['From'] = from_email
        msg['To'] = gmail
        msg['Subject'] = subject
        msg.attach(MIMEText(body, 'plain'))

        try:
            server = smtplib.SMTP('smtp.gmail.com', 587)
            server.starttls()
            server.login(from_email, from_password)
            text = msg.as_string()
            server.sendmail(from_email, gmail, text)
            server.quit()
            print("郵件發送成功")
        except Exception as e:
            print(f"郵件發送失敗: {e}")
            return jsonify({"error": "郵件發送失敗"}), 500

        return jsonify({"message": "驗證碼已發送"}), 200
    else:
        return jsonify({"error": "該 Email 不存在"}), 404

@app.route('/verify_code', methods=['POST'])
def verify_code():
    data = request.json
    gmail = data['gmail']
    code = data['code']

    if gmail in verification_codes:
        if verification_codes[gmail]['code'] == code:
            if datetime.now() < verification_codes[gmail]['expires']:
                return jsonify({"message": "驗證成功"}), 200
            else:
                return jsonify({"error": "驗證碼已過期"}), 400
        else:
            return jsonify({"error": "驗證碼錯誤"}), 400
    else:
        return jsonify({"error": "無效的驗證請求"}), 404

# API 3: 重置密碼
@app.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.json
    gmail = data['gmail']
    new_password = data['new_password']

    if gmail in verification_codes:
        if datetime.now() < verification_codes[gmail]['expires']:
            # 更新資料庫中的密碼
            cursor = db_gh_members.cursor()
            hashed_password = generate_password_hash(new_password) 
            cursor.execute("UPDATE members SET password = %s WHERE gmail = %s", (hashed_password, gmail))
            db_gh_members.commit()

            # 刪除驗證碼
            del verification_codes[gmail]
            return jsonify({"message": "密碼已重設"}), 200
        else:
            return jsonify({"error": "驗證碼已過期"}), 400
    else:
        return jsonify({"error": "無效的請求"}), 404

@app.route('/search', methods=['POST'])
def search_houses():
    filters = request.json
    query = """
        SELECT nh.*, ol.genderlimit, ol.pet, ol.fire 
        FROM new_housedetail nh 
        LEFT JOIN otherlimit ol ON nh.hid = ol.hid 
        WHERE 1=1
    """
    params = []
    
    if filters.get('city'):  # String 城市
        query += " AND city = %s"
        params.append(filters['city'])

    if filters.get('district'):  # String 地區
        query += " AND district = %s"
        params.append(filters['district'])

    if filters.get('room_type'):  # [int, int] 房屋類型
        room_type = filters.get('room_type')
        if room_type in ["獨立套房", "雅房", "分租套房"]:
            query += " AND pattern = %s"
            params.append(room_type)
        elif room_type == "整層住家":
            query += " AND (pattern = %s OR pattern LIKE %s) AND pattern NOT IN ('獨立套房', '分租套房', '雅房') "
            params.append('整層住家')
            params.append('%' + '房' + '%')

    if filters.get('rental_range'):  # [int, int] 租金
        rental_range = filters['rental_range']
        if rental_range[0] != -1:
            query += " AND price >= %s"
            params.append(rental_range[0])
        if rental_range[1] != -1:
            query += " AND price <= %s"
            params.append(rental_range[1])

    if filters.get('room_count'):  # String 房數
        room_count = filters.get('room_count')
        if room_count == 4:
            query += " AND CAST(SUBSTRING_INDEX(pattern, '房', 1) AS UNSIGNED) >= %s"
            params.append(room_count)
        else:
            query += " AND CAST(SUBSTRING_INDEX(pattern, '房', 1) AS UNSIGNED) = %s"
            params.append(room_count)

    if filters.get('house_size'):  # [int, int] 坪數
        house_size = filters['house_size']
        if house_size[0] != -1:
            query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS UNSIGNED) >= %s"
            params.append(house_size[0])
        if house_size[1] != -1:
            query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS UNSIGNED) <= %s"
            params.append(house_size[1])

    if filters.get('house_type'):  # String 房型
        query += " AND type = %s"
        params.append(filters['house_type'])

    # 更新 other limits 篩選邏輯
    other_options = filters.get('other_options', "").split(',')
    if '可養寵物' in other_options:
        query += " AND ol.pet = '可'"
    if '可開伙' in other_options:
        query += " AND ol.fire = '可'"
    if '限男' in other_options:
        query += " AND ol.genderlimit = '限男'"
    elif '限女' in other_options:
        query += " AND ol.genderlimit = '限女'"
    if '過濾重複刊登' in other_options:
        query += """
        AND nh.create_time = (
            SELECT MIN(nh2.create_time) 
            FROM new_housedetail nh2 
            WHERE nh2.same = nh.same
        )
        """
        
    

    cursor = db_gh_members.cursor()
    cursor.execute("USE gh_members")
    cursor.execute(query, params)
    results = cursor.fetchall()

    data = []
    for result in results:
        PHOTO_DIRECTORY = 'C:/jpg'  # 圖片存取路徑
        house_photo_directory = os.path.join(PHOTO_DIRECTORY, result[0])
        if not os.path.exists(house_photo_directory):
            image_urls = ""
        else:
            image_urls = f"http://4.227.176.245:5000/houses/{result[0]}/image1.jpg"

        data.append({
            'hid': result[0],
            'url': result[1],
            'title': result[2],
            'pattern': result[3],
            'size': result[4],
            'layer': result[5],
            'type': result[6],
            'price': result[7],
            'deposit': result[8],
            'city': result[9],
            'district': result[10],
            'address': result[11],
            'subway': result[12],
            'bus': result[13],
            'imageUrl': image_urls,
            'genderlimit': result[16],  
            'pet': result[17],  
            'fire': result[18],  
        })

    print(f"{query}\n\n{params}")
    print(data)

    return jsonify(data), 200


@app.route('/houses/<hid>', methods=['GET'])
def get_house_details(hid):
    cursor = db_gh_members.cursor()

    try:
        cursor.execute("USE gh_members")
        cursor.execute("""
            SELECT title, city, district, address, type, agency, layer, pattern, 
                   price, deposit, content, size, hid 
            FROM new_housedetail 
            WHERE hid=%s
        """, (hid,))
        results = cursor.fetchone()

        if not results:
            return jsonify({'error': 'House not found'}), 404


        cursor.execute("""
            SELECT refrigerator, washing_machine, television, air_conditioner, 
                   water_heater, bed, wardrobe, cable_tv, internet, 
                   natural_gas, sofa, table_chair, balcony, 
                   elevator, parking_space 
            FROM new_service 
            WHERE hid=%s
        """, (hid,))
        services = cursor.fetchone()
        services_dict = {
            '冰箱': services[0] == 1,
            '洗衣機': services[1] == 1,
            '電視': services[2] == 1,
            '冷氣': services[3] == 1,
            '熱水器': services[4] == 1,
            '床': services[5] == 1,
            '衣櫃': services[6] == 1,
            '第四台': services[7] == 1,
            '網路': services[8] == 1,
            '天然瓦斯': services[9] == 1,
            '沙發': services[10] == 1,
            '桌椅': services[11] == 1,
            '陽台': services[12] == 1,
            '電梯': services[13] == 1,
            '車位': services[14] == 1,
        }

        cursor.execute("""
            SELECT water, electric, management, parking 
            FROM pricecontain 
            WHERE hid=%s
        """, (hid,))
        pricecontain_results = cursor.fetchone()
        pricecontain = []
        if pricecontain_results:
            if pricecontain_results[0] == 1:
                pricecontain.append("水費")
            if pricecontain_results[1] == 1:
                pricecontain.append("電費")
            if pricecontain_results[2] == 1:
                pricecontain.append("管理費")
            if pricecontain_results[3] == 1:
                pricecontain.append("停車費")

        cursor.execute("""
            SELECT pet, fire, genderlimit 
            FROM otherlimit 
            WHERE hid=%s
        """, (hid,))
        otherlimitresults = cursor.fetchone()
        if otherlimitresults:
            pet = otherlimitresults[0]
            fire = otherlimitresults[1]
            genderlimit = otherlimitresults[2]
        else:
            pet = None
            fire = None
            genderlimit = None

        PHOTO_DIRECTORY = 'C:/jpg'
        house_photo_directory = os.path.join(PHOTO_DIRECTORY, str(hid))
        if not os.path.exists(house_photo_directory):
            image_urls = []
        else:
            image_files = [f for f in os.listdir(house_photo_directory) if os.path.isfile(os.path.join(house_photo_directory, f))]
            image_urls = [f"http://4.227.176.245:5000/houses/{hid}/{img}" for img in image_files]

        agency_name = results[5]
        if '先生' in agency_name:
            agency_name = agency_name.split('先生')[0][-1] + '先生'
        elif '小姐' in agency_name:
            agency_name = agency_name.split('小姐')[0][-1] + '小姐'
        else:
            agency_name = '王小明'

        data = {
            'title': results[0],
            'city': results[1],
            'district': results[2],
            'address': results[3],
            'type': results[4],
            'houseType': results[4],
            'ownerType': "屋主" if "屋主" in results[5] else "房仲",
            'floor': results[6],
            'layer': results[6],
            'pattern': results[7],
            'price': results[8],
            'deposit': results[9],
            'propertyRegistration': 'undefined',
            'service': services_dict,
            'content': results[10],
            'size': results[11],
            'hid': results[12],
            'imageUrl': image_urls,
            'lessorname': results[5],
            'pricecontain': pricecontain,
            'pet': pet,
            'fire': fire,
            'genderlimit': genderlimit,
        }

        return jsonify(data), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500





# todo 取得單張圖片
@app.route('/houses/<hid>/<filename>', methods=['GET'])
def get_photo(hid, filename):
    PHOTO_DIRECTORY = 'C:/jpg'  #! 圖片存取路徑
    return send_from_directory(os.path.join(PHOTO_DIRECTORY, hid), filename), 200

#todo 更改會員資料
@app.route('/update_user', methods=['POST'])
def update_user():
    data = request.json
    member_id = data['member_id']
    username = data['username']
    gmail = data['gmail']
    phone = data['phone']

    cursor = db_gh_members.cursor()
    cursor.execute("USE gh_members")
    cursor.execute("UPDATE members SET username = %s, gmail = %s, phone = %s WHERE member_id = %s", (username, gmail, phone, member_id))

    db_gh_members.commit()
    return jsonify({'message': '更改成功'}), 200

@app.route('/search_properties', methods=['POST'])
def search_properties():
    filters = request.json
    subscription_id = filters.get('subscription_id')
    
    if not subscription_id:
        return jsonify({'error': 'Subscription ID is required'}), 400

    
    cursor_members = db_gh_members.cursor()
    cursor_members.execute("USE gh_members")
    cursor_members.execute("SELECT last_check_time FROM subscriptions WHERE subscription_id = %s", (subscription_id,))
    last_check_time_result = cursor_members.fetchone()

    if not last_check_time_result:
        return jsonify({'error': 'No last_check_time found for the given member ID'}), 404

    last_check_time = last_check_time_result[0]
    query = "SELECT * FROM new_housedetail WHERE create_time > %s"
    params = [last_check_time]

    
    if filters.get('city'): #* String 城市
        query += " AND city = %s"
        params.append(filters['city'])

    if filters.get('district'):  # 地區
        if filters['district'] and filters['district'] != ['不限']:
            district_conditions = []
            for district in filters['district']:
                district_conditions.append("district LIKE %s")
                params.append(f"%{district}%")
            query += " AND (" + " OR ".join(district_conditions) + ")"

    if filters.get('pattern') and filters['pattern'] != ['不限']: 
        pattern_conditions = []
        for pattern in filters['pattern']:
            pattern_conditions.append("pattern = %s")
            params.append(pattern)
        query += " AND (" + " OR ".join(pattern_conditions) + ")"

    if filters.get('rentalrange') and filters['rentalrange'] != '不限':  
        rental_range = filters['rentalrange'].replace('元', '').replace(',', '').split('－')
        if len(rental_range) == 2:
            min_rent, max_rent = rental_range
            if min_rent:
                query += " AND price >= %s"
                params.append(int(min_rent))
            if max_rent:
                query += " AND price <= %s"
                params.append(int(max_rent))

    if filters.get('roomcount') and filters['roomcount'] != '不限':  
        room_count = filters['roomcount'].replace('房', '').replace('以上', '')
        if room_count.isdigit():
            query += " AND CAST(SUBSTRING_INDEX(pattern, '房', 1) AS UNSIGNED) = %s"
            params.append(int(room_count))

    if filters.get('size') and filters['size'] != '不限':  
        size_range = filters['size'].replace('坪', '').split('－')
        if len(size_range) == 2:
            min_size, max_size = size_range
            if min_size.isdigit():
                query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS UNSIGNED) >= %s"
                params.append(int(min_size))
            if max_size.isdigit():
                query += " AND CAST(SUBSTRING_INDEX(size, '坪', 1) AS UNSIGNED) <= %s"
                params.append(int(max_size))

    if filters.get('type') and filters['type'] != ['不限']:  
        type_conditions = []
        for house_type in filters['type']:
            type_conditions.append("type = %s")
            params.append(house_type)
        query += " AND (" + " OR ".join(type_conditions) + ")"

    
    query += " ORDER BY create_time DESC"

    cursor_members = db_gh_members.cursor()
    cursor_members.execute("USE gh_members")
    cursor_members.execute(query, params)
    results = cursor_members.fetchall()
    

    data = []
    for result in results:
        PHOTO_DIRECTORY = 'C:/jpg'  #! 圖片存取路徑
        house_photo_directory = os.path.join(PHOTO_DIRECTORY, result[0])
        if not os.path.exists(house_photo_directory):
            image_urls = ""
        else:
            image_urls = f"http://4.227.176.245:5000/houses/{result[0]}/image1.jpg"
    for result in results:
        data.append({
            'hid':result[0],
            'url': result[1],
            'title': result[2],
            'pattern':result[3],
            'size':result[4],
            'layer':result[5],
            'type':result[6],
            'price':result[7],
            'deposit':result[8],
            'city':result[9],
            'district':result[10],
            'address':result[11],
            'subway':result[12],
            'bus':result[13],
            'create_time':result[21],
            'imageUrl': image_urls,
        })
        
    print(f"{query}\n\n{params}")
    print(data)

    return jsonify(data), 200



@app.route('/add_subscription', methods=['POST'])
def add_subscription():
    criteria = request.json
    memberid = criteria.get('member_id')

    if not memberid:
        return jsonify({'message': 'Member ID is required'}), 400

    cursor = db_gh_members.cursor()
    subscription_time = datetime.now()
    last_check_time = subscription_time

    query = """
        INSERT INTO subscriptions (member_id, criteria, subscription_time, last_check_time) 
        VALUES (%s, %s, %s, %s)
    """
    params = (memberid, json.dumps(criteria), subscription_time, last_check_time)

    try:
        cursor.execute(query, params)
        db_gh_members.commit()
        subscription_id = cursor.lastrowid  
        return jsonify({'message': 'Subscription added successfully', 'subscription_time': subscription_time, 'subscription_id': subscription_id}), 200
    except Exception as e:
        db_gh_members.rollback()
        print(f"Error: {e}")
        return jsonify({'message': 'Failed to add subscription', 'error': str(e)}), 500

@app.route('/delete_subscription', methods=['POST'])
def delete_subscription():
    subscription_id = request.json.get('subscription_id')

    if not subscription_id:
        return jsonify({'message': 'Subscription ID is required'}), 400

    cursor = db_gh_members.cursor()

    try:
        cursor.execute("DELETE FROM subscriptions WHERE subscription_id = %s", (subscription_id,))
        db_gh_members.commit()
        return jsonify({'message': 'Subscription deleted successfully'}), 200
    except Exception as e:
        db_gh_members.rollback()
        print(f"Error: {e}")
        return jsonify({'message': 'Failed to delete subscription', 'error': str(e)}), 500
    
@app.route('/get_subscriptions', methods=['POST'])
def get_subscriptions():
    member_id = request.json.get('member_id')

    if not member_id:
        return jsonify({'message': 'Member ID is required'}), 400

    cursor = db_gh_members.cursor(dictionary=True)
    cursor.execute("SELECT subscription_id, criteria FROM subscriptions WHERE member_id = %s", (member_id,))
    results = cursor.fetchall()

    if not results:
        return jsonify({'message': 'No subscriptions found for the given Member ID'}), 404

    subscriptions = []
    for result in results:
        criteria = json.loads(result['criteria'])  # 解析 JSON 字符串为字典

        subscription_data = {
            'subscription_id': result['subscription_id'],
            'city': criteria.get('city'),
            'district': criteria.get('district', []),
            'pattern': criteria.get('pattern', []),
            'rentalrange': criteria.get('rentalrange'),
            'roomcount': criteria.get('roomcount'),
            'size': criteria.get('size'),
            'type': criteria.get('type', []),
        }

        subscriptions.append(subscription_data)

    return jsonify(subscriptions), 200


@app.route('/update_last_check_time', methods=['POST'])
def update_last_check_time():
    data = request.json
    subscription_id = data.get('subscription_id')
    member_id = data.get('member_id')

    if not subscription_id or not member_id:
        return jsonify({'message': 'Subscription ID and Member ID are required'}), 400

    cursor = db_gh_members.cursor()
    last_check_time = datetime.now()  
    query = "UPDATE subscriptions SET last_check_time = %s WHERE subscription_id = %s AND member_id = %s"
    params = (last_check_time, subscription_id, member_id)

    try:
        print(f"Executing query: {query} with params: {params}")
        cursor.execute(query, params)
        db_gh_members.commit()
        print('Last check time updated successfully')
        return jsonify({'message': 'Last check time updated successfully'}), 200
    except Exception as e:
        db_gh_members.rollback()
        print(f"Error: {e}")
        return jsonify({'message': 'Failed to update last check time', 'error': str(e)}), 500

# 設定靜態文件夾
UPLOAD_FOLDER = 'C:/jpg'  # 更新這裡的路徑為 jpg 資料夾
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

# 提供圖片的靜態文件服務
@app.route('/houses/<hid>/<filename>')
def uploaded_file(hid, filename):
    return send_from_directory(os.path.join(app.config['UPLOAD_FOLDER'], hid), filename)

@app.route('/add_house', methods=['POST'])
def add_house():
    try:
        data = request.form
        images = request.files.getlist('images')
        member_id = data.get('member_id')  
        
        if not member_id:
            return jsonify({"error": "缺少 member_id"}), 400

        hid = str(uuid.uuid4().int)[:8]
        size = f"{data['size']}坪"

        water = 1 if '水費' in data['pricecontain'] else 0
        electric = 1 if '電費' in data['pricecontain'] else 0
        management = 1 if '管理費' in data['pricecontain'] else 0
        parking = 1 if '停車費' in data['pricecontain'] else 0


        refrigerator = 1 if '冰箱' in data['service'] else 0
        washing_machine = 1 if '洗衣機' in data['service'] else 0
        television = 1 if '電視' in data['service'] else 0       
        air_conditioner = 1 if '冷氣' in data['service'] else 0
        water_heater = 1 if '熱水器' in data['service'] else 0
        bed = 1 if '床' in data['service'] else 0
        wardrobe = 1 if '衣櫃' in data['service'] else 0
        cable_tv = 1 if '第四台' in data['service'] else 0
        internet = 1 if '網路' in data['service'] else 0
        natural_gas = 1 if '天然瓦斯' in data['service'] else 0
        sofa = 1 if '沙發' in data['service'] else 0
        table_chair = 1 if '桌椅' in data['service'] else 0
        balcony = 1 if '陽台' in data['service'] else 0
        elevator = 1 if '電梯' in data['service'] else 0
        parking_space = 1 if '車位' in data['service'] else 0

        upload_folder = os.path.join(app.config['UPLOAD_FOLDER'], hid)
        if not os.path.exists(upload_folder):
            os.makedirs(upload_folder)

        image_paths = []
        for index, image in enumerate(images):
            filename = f"image{index + 1}.jpg"  # 按顺序命名文件
            image_path = os.path.join(upload_folder, filename)
            image.save(image_path)
            image_paths.append(f"/houses/{hid}/{filename}")
        with db_gh_members.cursor() as cursor:
            sql_house = """
                INSERT INTO new_housedetail (
                    hid, title, pattern, size, layer, deposit, type, price, 
                    city, district, address, agency, member_id, phone, content
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql_house, (
                hid, data['title'], data['pattern'], size, data['layer'], data['deposit'],
                data['type'], data['price'], data['city'], data['district'], data['address'],
                data['agency'], member_id, data['phone'], data['content']
            ))

            sql_fee = """
                INSERT INTO pricecontain (
                    hid, water, electric, management, parking
                ) VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(sql_fee, (
                hid, water, electric, management, parking
            ))

            sql_service = """
                INSERT INTO new_service (hid, refrigerator, washing_machine, television, air_conditioner, water_heater, bed, wardrobe, cable_tv, internet, natural_gas, sofa, table_chair, balcony, elevator, parking_space)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """

            cursor.execute(sql_service, (
                hid, refrigerator, washing_machine, television, air_conditioner, water_heater, bed, wardrobe, cable_tv, internet, natural_gas, sofa, table_chair, balcony, elevator, parking_space
            ))

            otherlimit = """
                INSERT INTO otherlimit (hid, genderlimit, pet, fire)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(otherlimit, (
                hid, data['genderlimit'], data['pet'], data['fire']
            ))
            for image_path in image_paths:
                sql_image = """
                    INSERT INTO house_images (hid, image_path)
                    VALUES (%s, %s)
                """
                cursor.execute(sql_image, (hid, image_path))

            db_gh_members.commit()

        return jsonify({"message": "House added successfully", "hid": hid, "images": image_paths}), 200
    except Exception as e:
        app.logger.error("Error occurred: %s", str(e))
        return jsonify({"error": str(e)}), 400

@app.route('/houses/<hid>', methods=['DELETE'])
def delete_house(hid):
    try:
        with db_gh_members.cursor() as cursor:
            cursor.execute("DELETE FROM new_housedetail WHERE hid = %s", (hid,))
            db_gh_members.commit()
        return jsonify({"message": "House deleted successfully"}), 200
    except Exception as e:
        app.logger.error("Error occurred while deleting house: %s", str(e))
        return jsonify({"error": str(e)}), 400


@app.route('/edit_house', methods=['POST'])
def edit_house():
    try:
        data = request.form
        hid = data['hid']
        images = request.files.getlist('images') if 'images' in request.files else []

        # 構建圖片保存的文件夾路徑
        upload_folder = os.path.join(app.config['UPLOAD_FOLDER'], hid)
        if not os.path.exists(upload_folder):
            os.makedirs(upload_folder)
        
        existing_images = os.listdir(upload_folder)
        start_index = len(existing_images) + 1  

        image_paths = []
        for index, image in enumerate(images):
            filename = f"image{start_index + index}.jpg" 
            image_path = os.path.join(upload_folder, filename)
            image.save(image_path)
            image_paths.append(f"/houses/{hid}/{filename}")

        updates = {}
        if 'title' in data:
            updates['title'] = data['title']
        if 'pattern' in data:
            updates['pattern'] = data['pattern']
        if 'size' in data:
            updates['size'] = f"{data['size']}坪"
        if 'layer' in data:
            updates['layer'] = data['layer']
        if 'deposit' in data:
            updates['deposit'] = data['deposit']
        if 'type' in data:
            updates['type'] = data['type']
        if 'price' in data:
            updates['price'] = data['price']
        if 'city' in data and 'district' in data:
            updates['city'] = data['city']
        if 'district' in data:
            updates['district'] = data['district']
        if 'address' in data:
            updates['address'] = data['address']
        if 'agency' in data:
            updates['agency'] = data['agency']
        if 'phone' in data:
            updates['phone'] = data['phone']
        if 'content' in data:
            updates['content'] = data['content']

        with db_gh_members.cursor() as cursor:
            if updates:
                update_fields = ', '.join(f"{key}=%s" for key in updates.keys())
                cursor.execute(f"""
                    UPDATE new_housedetail
                    SET {update_fields}
                    WHERE hid=%s
                """, tuple(updates.values()) + (hid,))
            
            if 'pricecontain' in data:
                pricecontain = data['pricecontain'].split(',')
                cursor.execute("""
                    UPDATE pricecontain
                    SET water=%s, electric=%s, management=%s, parking=%s
                    WHERE hid=%s
                """, (
                    1 if '水費' in pricecontain else 0,
                    1 if '電費' in pricecontain else 0,
                    1 if '管理費' in pricecontain else 0,
                    1 if '停車費' in pricecontain else 0,
                    hid
                ))

            if 'service' in data:
                service = data['service'].split(',')
                service_updates = {
                    'refrigerator': 1 if '冰箱' in service else 0,
                    'washing_machine': 1 if '洗衣機' in service else 0,
                    'television': 1 if '電視' in service else 0,
                    'air_conditioner': 1 if '冷氣' in service else 0,
                    'water_heater': 1 if '熱水器' in service else 0,
                    'bed': 1 if '床' in service else 0,
                    'wardrobe': 1 if '衣櫃' in service else 0,
                    'cable_tv': 1 if '第四台' in service else 0,
                    'internet': 1 if '網路' in service else 0,
                    'natural_gas': 1 if '天然瓦斯' in service else 0,
                    'sofa': 1 if '沙發' in service else 0,
                    'table_chair': 1 if '桌椅' in service else 0,
                    'balcony': 1 if '陽台' in service else 0,
                    'elevator': 1 if '電梯' in service else 0,
                    'parking_space': 1 if '車位' in service else 0,
                }

                update_service_fields = ', '.join([f"{key}=%s" for key in service_updates.keys()])
                cursor.execute(f"""
                    UPDATE new_service
                    SET {update_service_fields}
                    WHERE hid=%s
                """, tuple(service_updates.values()) + (hid,))

            if 'genderlimit' in data or 'pet' in data or 'fire' in data:
                update_limit_fields = []
                update_limit_values = []

                if 'genderlimit' in data:
                    update_limit_fields.append("genderlimit=%s")
                    update_limit_values.append(data['genderlimit'])

                if 'pet' in data:
                    update_limit_fields.append("pet=%s")
                    update_limit_values.append(data['pet'])

                if 'fire' in data:
                    update_limit_fields.append("fire=%s")
                    update_limit_values.append(data['fire'])

                if update_limit_fields:
                    cursor.execute(f"""
                        UPDATE otherlimit
                        SET {', '.join(update_limit_fields)}
                        WHERE hid=%s
                    """, tuple(update_limit_values) + (hid,))

            # 更新圖片路徑到資料庫
            for image_path in image_paths:
                cursor.execute("""
                    INSERT INTO house_images (hid, image_path)
                    VALUES (%s, %s)
                """, (hid, image_path))

            db_gh_members.commit()

        return jsonify({"message": "House updated successfully"}), 200
    except Exception as e:
        app.logger.error("Error occurred: %s", str(e))
        return jsonify({"error": str(e)}), 400

@app.route('/houses_by_member/<int:member_id>', methods=['GET'])
def get_houses_by_member(member_id):
    try:
        with db_gh_members.cursor(dictionary=True) as cursor:
            # 使用 JOIN 將其他表格的資料連接到房屋資料中
            cursor.execute("""
                SELECT 
                    nh.*, 
                    pc.water, pc.electric, pc.management, pc.parking,
                    ns.refrigerator, ns.washing_machine, ns.television, ns.air_conditioner, 
                    ns.water_heater, ns.bed, ns.wardrobe, ns.cable_tv, ns.internet, 
                    ns.natural_gas, ns.sofa, ns.table_chair, ns.balcony, ns.elevator, ns.parking_space,
                    ol.genderlimit, ol.pet, ol.fire
                FROM new_housedetail nh
                LEFT JOIN pricecontain pc ON nh.hid = pc.hid
                LEFT JOIN new_service ns ON nh.hid = ns.hid
                LEFT JOIN otherlimit ol ON nh.hid = ol.hid
                WHERE nh.member_id = %s
            """, (member_id,))
            
            houses = cursor.fetchall()
            for house in houses:
                cursor.execute("SELECT image_path FROM house_images WHERE hid = %s", (house['hid'],))
                images = cursor.fetchall()
                house['images'] = [img['image_path'].replace('/uploads', '/houses') for img in images]


        formatted_houses = []
        for house in houses:
            pricecontain_list = []
            if house['water']:
                pricecontain_list.append('水費')
            if house['electric']:
                pricecontain_list.append('電費')
            if house['management']:
                pricecontain_list.append('管理費')
            if house['parking']:
                pricecontain_list.append('停車費')
            
            service_list = []
            if house['refrigerator']:
                service_list.append('冰箱')
            if house['washing_machine']:
                service_list.append('洗衣機')
            if house['television']:
                service_list.append('電視')
            if house['air_conditioner']:
                service_list.append('冷氣')
            if house['water_heater']:
                service_list.append('熱水器')
            if house['bed']:
                service_list.append('床')
            if house['wardrobe']:
                service_list.append('衣櫃')
            if house['cable_tv']:
                service_list.append('第四台')
            if house['internet']:
                service_list.append('網路')
            if house['natural_gas']:
                service_list.append('天然瓦斯')
            if house['sofa']:
                service_list.append('沙發')
            if house['table_chair']:
                service_list.append('桌椅')
            if house['balcony']:
                service_list.append('陽台')
            if house['elevator']:
                service_list.append('電梯')
            if house['parking_space']:
                service_list.append('車位')

            house['pricecontain'] = pricecontain_list
            house['service'] = service_list

            formatted_houses.append(house)

        # 使用 print 函數進行輸出
        print("Fetched houses data:", houses)
        
        # 仍然使用 app.logger 記錄信息，確保配置正確時會輸出
        app.logger.info("Fetched houses data: %s", houses)

        return jsonify(houses), 200
    except Exception as e:
        app.logger.error("Error occurred: %s", str(e))
        return jsonify({"error": str(e)}), 400

    
    
@app.route('/favorites', methods=['POST'])
def add_favorite():
    data = request.get_json()
    member_id = data['member_id']
    hid = data['hid']

    try:
        
        cursor = db_gh_members.cursor()
        cursor.execute("USE gh_members")
        
        
        cursor.execute("INSERT INTO favorite (member_id, hid) VALUES (%s, %s)", (member_id, hid))
        db_gh_members.commit()
        cursor.close()
        
        return jsonify({"status": "success"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400
    
@app.route('/favorites', methods=['DELETE'])
def delete_favorite():
    data = request.get_json()
    member_id = data['member_id']
    hid = data['hid']

    try:
        cursor = db_gh_members.cursor()
        cursor.execute("USE gh_members")

        # 刪除收藏
        cursor.execute("DELETE FROM favorite WHERE member_id = %s AND hid = %s", (member_id, hid))
        db_gh_members.commit()
        cursor.close()
        
        return jsonify({"status": "deleted"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route('/favorites/<int:member_id>', methods=['GET'])
def get_favorites(member_id):
    try:
        # 使用 gh_members 資料庫
        cursor = db_gh_members.cursor()
        cursor.execute("USE gh_members")
        
        # 獲取收藏的房屋ID
        cursor.execute("SELECT hid FROM favorite WHERE member_id = %s", (member_id,))
        favorite_houses = cursor.fetchall()

        if not favorite_houses:
            return jsonify([]), 200

        # 獲取收藏房屋的詳細資料
        house_ids = [house[0] for house in favorite_houses]
        format_strings = ','.join(['%s'] * len(house_ids))
        cursor.execute(f"SELECT * FROM new_housedetail WHERE hid IN ({format_strings})", tuple(house_ids))
        results = cursor.fetchall()

        # 組裝返回的資料
        data = []
        default_image_url = "http://your-server-url/path-to-default-image.jpg"  # 替換為你的預設圖片URL
        for result in results:
            PHOTO_DIRECTORY = 'C:/jpg'  # 圖片存取路徑
            house_photo_directory = os.path.join(PHOTO_DIRECTORY, result[0])
            if not os.path.exists(house_photo_directory) or not os.listdir(house_photo_directory):
                image_urls = default_image_url
            else:
                image_urls = f"http://4.227.176.245:5000/houses/{result[0]}/image1.jpg"

            data.append({
                'hid': result[0],
                'url': result[1],
                'title': result[2],
                'pattern': result[3],
                'size': result[4],
                'layer': result[5],
                'type': result[6],
                'price': result[7],
                'deposit': result[8],
                'city': result[9],
                'district': result[10],
                'address': result[11],
                'subway': result[12],
                'bus': result[13],
                'imageUrl': image_urls
            })

        return jsonify(data), 200

    except Exception as e:
        app.logger.error("Error occurred: %s", str(e))
        return jsonify({"error": str(e)}), 400

@app.route('/record_click', methods=['POST'])
def record_click():
    member_id = request.json.get('member_id')
    hid = request.json.get('hid')

    print("Received member_id:", member_id)
    print("Received hid:", hid)

    if not member_id or not hid:
        return jsonify({"error": "Missing member_id or hid"}), 400

    try:
        with db_gh_members.cursor() as cursor:
            print("Cursor created successfully.")
            cursor.execute("SELECT id FROM clickrecord WHERE member_id = %s AND hid = %s", (member_id, hid))
            existing_click = cursor.fetchone()

            print("Query executed. Existing click:", existing_click)

            if existing_click:
                return jsonify({"message": "Click already recorded"}), 200

            cursor.execute("INSERT INTO clickrecord (member_id, hid) VALUES (%s, %s)", (member_id, hid))
            db_gh_members.commit()

            print("Click recorded successfully.")
            return jsonify({"message": "Click recorded successfully"}), 200

    except Exception as e:
        print("Error occurred:", str(e))
        return jsonify({"error": str(e)}), 500
    
@app.route('/clear_click_records', methods=['POST'])
def clear_click_records():
    try:
        with db_gh_members.cursor() as cursor:
            print("Clearing all click records.")
            cursor.execute("DELETE FROM clickrecord")
            db_gh_members.commit()
            print("All click records cleared successfully.")
            return jsonify({"message": "All click records cleared successfully"}), 200

    except Exception as e:
        print("Error occurred while clearing records:", str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/get_clicks/<int:member_id>', methods=['GET'])
def get_clicks(member_id):
    try:
        with db_gh_members.cursor() as cursor:
            cursor.execute("USE gh_members")

            cursor.execute("SELECT hid FROM clickrecord WHERE member_id = %s", (member_id,))
            clicked_houses = cursor.fetchall()

            if not clicked_houses:
                return jsonify([]), 200
            
            house_ids = [house[0] for house in clicked_houses]
            format_strings = ','.join(['%s'] * len(house_ids))
            cursor.execute(f"SELECT * FROM new_housedetail WHERE hid IN ({format_strings})", tuple(house_ids))
            results = cursor.fetchall()

            data = []
            default_image_url = "http://your-server-url/path-to-default-image.jpg"
            for result in results:
                PHOTO_DIRECTORY = 'C:/jpg'
                house_photo_directory = os.path.join(PHOTO_DIRECTORY, result[0])
                if not os.path.exists(house_photo_directory) or not os.listdir(house_photo_directory):
                    image_urls = default_image_url
                else:
                    image_urls = f"http://4.227.176.245:5000/houses/{result[0]}/image1.jpg"

                data.append({
                    'hid': result[0],
                    'url': result[1],
                    'title': result[2],
                    'pattern': result[3],
                    'size': result[4],
                    'layer': result[5],
                    'type': result[6],
                    'price': result[7],
                    'deposit': result[8],
                    'city': result[9],
                    'district': result[10],
                    'address': result[11],
                    'subway': result[12],
                    'bus': result[13],
                    'imageUrl': image_urls,
                })

            return jsonify(data), 200

    except Exception as e:
        app.logger.error("Error occurred: %s", str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/save_click', methods=['POST'])
def save_click():
    data = request.json
    member_id = data.get('member_id')
    hid = data.get('hid')

    if not member_id or not hid:
        return jsonify({'error': '缺少 member_id 或 hid'}), 400

    try:
        with db_gh_members.cursor() as cursor:
            cursor.execute("INSERT INTO lineclickrecord (member_id, hid) VALUES (%s, %s)", (member_id, hid))
            db_gh_members.commit()

        send_to_line_bot(member_id, hid)

        return jsonify({'message': '用戶點擊已保存'}), 200

    except Exception as e:
        db_gh_members.rollback()
        return jsonify({'error': str(e)}), 500

def send_to_line_bot(member_id, hid):
    import requests
    

    line_bot_url = f"https://liff.line.me/1645278921-kWRPP32q/?accountId=204wjleq?member_id={member_id}&hid={hid}" 
    payload = {
        'member_id': member_id,
        'hid': hid
    }
    headers = {'Content-Type': 'application/json'}

    response = requests.post(line_bot_url, json=payload, headers=headers)

    if response.status_code != 200:
        print(f"Failed to send data to LINE Bot: {response.status_code}, {response.text}")

#todo 
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)