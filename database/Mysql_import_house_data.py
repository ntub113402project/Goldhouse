import mysql.connector
import json

# 讀取 JSON 檔案
with open('detail.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 連接 MySQL 資料庫
conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='ntubGH113402',
    database='ghdetail'
)
cursor = conn.cursor()

# 創建名為 ghdetail 的資料庫
cursor.execute('CREATE DATABASE IF NOT EXISTS ghdetail')

# 使用 ghdetail 資料庫
cursor.execute('USE ghdetail')

# 清空 housedetail 表格
cursor.execute('TRUNCATE TABLE housedetail')

# 創建名為 housedetail 的表格
cursor.execute('''
    CREATE TABLE IF NOT EXISTS housedetail (
        hid VARCHAR(255) PRIMARY KEY,
        url VARCHAR(255),
        title VARCHAR(255),
        pattern VARCHAR(255),
        size VARCHAR(255),
        layer VARCHAR(255),
        type VARCHAR(255),
        price INT,
        deposit VARCHAR(255),
        address VARCHAR(255),
        subway TEXT,
        bus TEXT,
        agency VARCHAR(255),
        agency_company VARCHAR(255),
        content TEXT
    )
''')

# 檢查並創建名為 service 的表格
cursor.execute('''
    CREATE TABLE IF NOT EXISTS service (
        id INT AUTO_INCREMENT PRIMARY KEY,
        hid VARCHAR(255),
        device VARCHAR(255),
        avaliable BOOLEAN,
        FOREIGN KEY (hid) REFERENCES housedetail(hid)
    )
''')

cursor.execute('DELETE FROM service')

# 插入 JSON 檔案的資料到 housedetail 表格和 service 表格中
for item in data:
    hid = item['hid']
    url = item['url']
    houseinfo = item['houseinfo']
    positionround = item['positionround']
    servicelist = item['servicelist']
    remark = item['remark']

    subway = ', '.join(positionround['subway'])
    bus = ', '.join(positionround['bus'])
    content = '\n'.join(remark['content'])

    # 插入到 housedetail 表格中
    sql_housedetail = '''
        INSERT INTO housedetail
        (hid, url, title, pattern, size, layer, type, price, deposit, address, subway, bus, agency, agency_company, content)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    '''
    val_housedetail = (hid, url, houseinfo['title'], houseinfo['pattern'], houseinfo['size'], houseinfo['layer'], houseinfo['type'], houseinfo['price'], houseinfo['deposit'], positionround['address'], subway, bus, remark['agency'], remark['agency_company'], content)
    cursor.execute(sql_housedetail, val_housedetail)

    # 插入到 service 表格中
    for service in servicelist:
        device = service['device']
        avaliable = service['avaliable']

        sql_service = '''
            INSERT INTO service
            (hid, device, avaliable)
            VALUES (%s, %s, %s)
        '''
        val_service = (hid, device, avaliable)
        cursor.execute(sql_service, val_service)

# 確認提交資料庫變更
conn.commit()

# 關閉游標和連接
cursor.close()
conn.close()

print("資料已成功匯入到 MySQL 資料庫中的 housedetail 表格和 service 表格。")
