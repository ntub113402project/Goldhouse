import mysql.connector
import json

# 連接 MySQL
mydb = mysql.connector.connect(
  host="localhost",  # 主機位置
  user="root",  # 使用者名稱
  password="ntubGH113402"# 密碼
 
)

# 創建 cursor 物件
mycursor = mydb.cursor()

# 讀取 JSON 檔案
with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 創建名為 GH113 的 database
mycursor.execute("CREATE DATABASE IF NOT EXISTS GH113")

# 使用 GH113 database
mycursor.execute("USE GH113")

# 創建名為 house 的 table
mycursor.execute("CREATE TABLE IF NOT EXISTS house (hid VARCHAR(255), url VARCHAR(255), title VARCHAR(255), price INT, address VARCHAR(255), traffic VARCHAR(255))")

# 插入資料到 MySQL 中的 table
for item in data:
    hid = item['hid']
    url = item['url']
    title = item['title']
    price = item['price']
    address = item['address']
    traffic = item['traffic']
    
    sql = "INSERT INTO house (hid, url, title, price, address, traffic) VALUES (%s, %s, %s, %s, %s, %s)"
    val = (hid, url, title, price, address, traffic)
    mycursor.execute(sql, val)

# 提交更改
mydb.commit()

# 關閉連接
mycursor.close()
mydb.close()
