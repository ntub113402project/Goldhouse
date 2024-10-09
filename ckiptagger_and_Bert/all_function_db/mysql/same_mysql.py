import mysql.connector
import json

# 連接到現有的資料庫
def connect_to_mysql():
    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='ntubGH113402',
            database='ghdetail'  # 現有的資料庫名稱
        )
        return connection
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return None

# 將 JSON 中的 same 編號更新到資料庫中的相應欄位
def update_same_in_mysql(json_file, connection):
    cursor = connection.cursor()

    # 定義 SQL 更新語句
    sql = """
        UPDATE gh_members.new_housedetail
        SET same = %s
        WHERE hid = %s
    """

    # 讀取 JSON 文件
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # 遍歷 JSON 數據，根據 hid 更新資料庫中的 same 欄位
    for item in data:
        hid = item.get('hid')  # 從 JSON 文件中取得 hid
        same = item.get('same')  # 從 JSON 文件中取得 same 編號

        if hid and same is not None:  # 確保 same 不是空值
            try:
                # 執行 SQL 更新操作
                cursor.execute(sql, (same, hid))
            except mysql.connector.Error as err:
                print(f"Failed to update hid {hid}: {err}")

    # 提交更改
    connection.commit()
    print("數據已成功更新到資料庫中")

# 主函數
def main():
    # JSON 文件路徑，這裡保存了比對後的結果
    json_file = "C:\\Users\\ntubgoldhouse\\Desktop\\Goldhouse\\ckiptagger_and_Bert\\all_function_db\\json結果\\similar_houses.json"

    # 連接到 MySQL 資料庫
    connection = connect_to_mysql()
    
    if connection:
        # 更新資料庫中的 same 欄位
        update_same_in_mysql(json_file, connection)

        # 關閉連接
        connection.close()

if __name__ == "__main__":
    main()
