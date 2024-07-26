import mysql.connector
import json
import os

# 使用原始字符串指定文件路徑
json_file_path = r'C:\Users\ntubgoldhouse\Desktop\Goldhouse\ner\nearby_ORG_cleaned.json'

# 檢查文件是否存在
if not os.path.exists(json_file_path):
    print(f"File not found: {json_file_path}")
    exit(1)

# 讀取 JSON 文件
with open(json_file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# 配置 MySQL 連接
connection = mysql.connector.connect(
    host="localhost",
    user="root",
    password="ntubGH113402",
    database="ghdetail"  
)
cursor = connection.cursor()

try:
    # 新增一個欄位
    alter_table_query = '''
    ALTER TABLE new_housedetail
    ADD COLUMN store JSON
    '''
    cursor.execute(alter_table_query)

    # 假設 JSON 數據包含 hid 作為用戶 ID 和 store 數據
    update_query = '''
    UPDATE new_housedetail
    SET store = %s
    WHERE hid = %s
    '''
    for entry in data:
        store_data = json.dumps(entry['store'])  # 將 store 數據轉換為 JSON 字符串
        cursor.execute(update_query, (store_data, entry['hid']))

    # 提交事務
    connection.commit()
except mysql.connector.Error as e:
    print(f"Error: {e}")
    connection.rollback()
finally:
    cursor.close()
    connection.close()
