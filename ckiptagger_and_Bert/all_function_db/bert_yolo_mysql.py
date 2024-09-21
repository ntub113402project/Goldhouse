import mysql.connector
import json

# 創建資料庫和表
def create_database_and_table():

    # 連接到 MySQL 伺服器
    connection = mysql.connector.connect(
        host="localhost",  
        user="root",  
        password="ntubGH113402"  
    )
    cursor = connection.cursor()

    # 創建新的資料庫
    cursor.execute("CREATE DATABASE IF NOT EXISTS vmvp")

    # 使用新創建的資料庫
    cursor.execute("USE vmvp")

    # 創建存儲 BERT 和 YOLO 結果的資料表
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS house_data (
            id INT AUTO_INCREMENT PRIMARY KEY,  -- 自動遞增的主鍵
            hid VARCHAR(255) NOT NULL,  -- 房屋的唯一識別碼
            VW_address JSON,  -- 地址的 BERT 向量，使用 JSON 類型存儲
            VW_pattern JSON,  -- 房屋類型的 BERT 向量，使用 JSON 類型存儲
            VW_size JSON,  -- 房屋大小的 BERT 向量
            VW_layer JSON,  -- 樓層的 BERT 向量
            VW_servicelist JSON,  -- 服務列表的 BERT 向量
            VP_images JSON  -- YOLO 檢測結果，包括物品名稱和顏色等
        )
    """)
    print("已創建")

    # 提交更改
    connection.commit()
    return connection, cursor

# 將 JSON 數據插入到 MySQL 資料庫
def insert_data_into_mysql(json_file, connection):
    cursor = connection.cursor()

    # 定義插入數據的 SQL 語句
    sql = """
        INSERT INTO house_data (hid, VW_address, VW_pattern, VW_size, VW_layer, VW_servicelist, VP_images)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """

    # 打開並讀取 JSON 文件
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 遍歷 JSON 數據並插入到資料庫
    for item in data:
        hid = item.get('hid')
        VW_address = json.dumps(item.get('VW_address'))  # 將 BERT 向量轉為 JSON 字串
        VW_pattern = json.dumps(item.get('VW_pattern'))
        VW_size = json.dumps(item.get('VW_size'))
        VW_layer = json.dumps(item.get('VW_layer'))
        VW_servicelist = json.dumps(item.get('VW_servicelist'))
        VP_images = json.dumps(item.get('VP_images'))  # YOLO 結果轉為 JSON 字串

        # 執行插入操作
        cursor.execute(sql, (hid, VW_address, VW_pattern, VW_size, VW_layer, VW_servicelist, VP_images))

    # 提交更改
    connection.commit()
    print("數據已成功插入到資料庫中")

# 主函數
def main():
    # 創建新資料庫和表
    connection, cursor = create_database_and_table()

    # JSON 文件路徑
    json_file = "C:\\Users\\ntubgoldhouse\\Desktop\\all_function_db\\merged_features_1.json"

    # 插入數據
    insert_data_into_mysql(json_file, connection)

    # 關閉連接
    cursor.close()
    connection.close()

if __name__ == "__main__":
    main()
