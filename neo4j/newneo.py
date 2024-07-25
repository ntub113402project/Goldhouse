from mysql.connector import connect, Error
from py2neo import Graph, Node, Relationship

# 連接到MySQL數據庫
try:
    mysql_conn = connect(
        host="localhost",
        user="root",
        password="ntubGH113402",
        database="ghdetail"
    )
    print("MySQL connection established.")
except Error as e:
    print(f"Error: {e}")

# 連接到Neo4j數據庫
graph = Graph("bolt://localhost:7687", auth=("neo4j", "12345678"))
print("Connection to Neo4j established successfully.")

# 從MySQL數據庫中抓取租屋資料
query = "SELECT hid, pattern, layer, type, price, size, address, subway, bus FROM housedetail"
with mysql_conn.cursor() as cursor:
    cursor.execute(query)
    result = cursor.fetchall()

# 將租屋資料導入Neo4j
for row in result:
    house = Node("House", hid=row[0], pattern=row[1], layer=row[2], type=row[3],
                 price=row[4], size=row[5], address=row[6],subway=row[7], bus=row[8])
    graph.create(house)

    # 創建地鐵節點並建立關係
    # if row[7]:
    #     subway_node = Node("Subway", name=row[7])
    #     graph.merge(subway_node, "Subway", "name")
    #     relationship = Relationship(house_node, "NEAR_SUBWAY", subway_node)
    #     graph.create(relationship)

    # # 創建與bus的關聯
    # if row[8]:
    #     bus_node = Node("Bus", name=row[8])
    #     graph.merge(bus_node, "Bus", "name")
    #     relationship = Relationship(house_node, "NEAR_BUS", bus_node)
    #     graph.create(relationship)

for id1, house_node1 in house.items():
    for id2, house_node2 in house.items():
        if id1 != id2:  # 排除自己與自己的關係
            # 這裡可以根據實際情況定義鄰近條件，例如地址接近或價格相似等
            # 假設條件是地址接近，這裡只是簡單的字符串包含判斷，具體條件可以更複雜
            if house_node1["address"][:5] == house_node2["address"][:5]:
                relationship = Relationship(house_node1, "NEAR", house_node2)
                graph.create(relationship)
   
