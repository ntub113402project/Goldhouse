import mysql.connector
import json

# 連接到現有資料庫並檢查表是否存在
def connect_to_existing_database():
    # 連接到 MySQL 伺服器和現有資料庫
    connection = mysql.connector.connect(
        host="localhost",  
        user="root",  
        password="ntubGH113402",  
        database="vmvp"  # 使用現有的資料庫
    )
    cursor = connection.cursor()

    # 檢查並創建存儲 BERT 和 YOLO 結果的資料表（如果尚未存在）
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS house_data (
            id INT AUTO_INCREMENT PRIMARY KEY,  -- 自動遞增的主鍵
            hid VARCHAR(255) NOT NULL UNIQUE,  -- 房屋的唯一識別碼，唯一約束
            VW_address JSON,  -- 地址的 BERT 向量，使用 JSON 類型存儲
            VW_pattern JSON,  -- 房屋類型的 BERT 向量，使用 JSON 類型存儲
            VW_size JSON,  -- 房屋大小的 BERT 向量
            VW_layer JSON,  -- 樓層的 BERT 向量
            VW_servicelist JSON,  -- 服務列表的 BERT 向量
            VP_images JSON  -- 圖片的 BERT 向量，存儲圖片 BERT 特徵
        )
    """)
    print("資料庫連接並檢查表結束")

    # 檢查是否有新增的欄位，若不存在則新增
    try:
        cursor.execute("SELECT VW_subway FROM house_data LIMIT 1")
    except mysql.connector.errors.ProgrammingError:
        cursor.execute("ALTER TABLE house_data ADD COLUMN VW_subway JSON")
        print("新增欄位 VW_subway")

    try:
        cursor.execute("SELECT VW_bus FROM house_data LIMIT 1")
    except mysql.connector.errors.ProgrammingError:
        cursor.execute("ALTER TABLE house_data ADD COLUMN VW_bus JSON")
        print("新增欄位 VW_bus")

    # 提交更改
    connection.commit()
    return connection, cursor

# 將 JSON 數據插入到 MySQL 資料庫
def insert_data_into_mysql(json_file, connection):
    cursor = connection.cursor()

    # 定義插入數據的 SQL 語句
    sql = """
        INSERT INTO house_data (hid, VW_address, VW_pattern, VW_size, VW_layer, VW_subway, VW_bus, VW_servicelist, VP_images)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE
        VW_address = VALUES(VW_address),
        VW_pattern = VALUES(VW_pattern),
        VW_size = VALUES(VW_size),
        VW_layer = VALUES(VW_layer),
        VW_subway = VALUES(VW_subway),
        VW_bus = VALUES(VW_bus),
        VW_servicelist = VALUES(VW_servicelist),
        VP_images = VALUES(VP_images)
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
        VW_subway = json.dumps(item.get('VW_subway'))
        VW_bus = json.dumps(item.get('VW_bus'))
        VW_servicelist = json.dumps(item.get('VW_servicelist'))
        VP_images = json.dumps(item.get('VP_images'))  # 圖片 BERT 向量轉為 JSON 字串

        # 執行插入操作，並在主鍵（hid）已存在的情況下更新數據
        cursor.execute(sql, (hid, VW_address, VW_pattern, VW_size, VW_layer, VW_subway, VW_bus, VW_servicelist, VP_images))

    # 提交更改
    connection.commit()
    print("數據已成功插入到資料庫中")

# 主函數
def main():
    # 連接到現有資料庫並檢查表
    connection, cursor = connect_to_existing_database()

    # JSON 文件路徑
    json_file = "D:\\merged_features.json"

    # 插入數據
    insert_data_into_mysql(json_file, connection)

    # 關閉連接
    cursor.close()
    connection.close()

if __name__ == "__main__":
    main()
