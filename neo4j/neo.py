# from mysql.connector import connect, Error
# from py2neo import Graph, Node, Relationship
# import time

# # 連接到MySQL數據庫
# try:
#     mysql_conn = connect(
#         host="localhost",
#         user="root",
#         password="ntubGH113402",
#         database="ghdetail"
#     )
#     print("MySQL connection established.")
# except Error as e:
#     print(f"Error: {e}")
#     exit()

# # 重試連接Neo4j的函數
# def connect_to_neo4j(retries=5, wait=2):
#     for attempt in range(retries):
#         try:
#             graph = Graph("bolt://localhost:7687", auth=("neo4j", "12345678"))
#             print("Neo4j connection established.")
#             return graph
#         except Exception as e:
#             print(f"Attempt {attempt + 1} failed: {e}")
#             time.sleep(wait)
#     print("Failed to connect to Neo4j after multiple attempts.")
#     exit()

# # 連接到Neo4j數據庫
# graph = connect_to_neo4j()

# # delete_query = """
# # MATCH ()-[r:NEAR]-()
# # DELETE r
# # """
# # graph.run(delete_query)

# # 從MySQL數據庫中抓取資料
# query = "SELECT hid, pattern, layer, type, price, size, address, subway, bus FROM housedetail"
# with mysql_conn.cursor() as cursor:
#     cursor.execute(query)
#     result = cursor.fetchall()

# # 創建House節點並導入Neo4j
# house_nodes = {}
# for row in result:
#     house_node = Node(
#         "House",
#         hid=row[0],
#         pattern=row[1],
#         layer=row[2],
#         type=row[3],
#         price=row[4],
#         size=row[5],
#         address=row[6]
#     )
#     graph.create(house_node)
#     house_nodes[row[0]] = house_node  # 保存節點以便後續使用

#     # 創建與subway的關聯
#     if row[7]:
#         subway_node = Node("Subway", name=row[7])
#         graph.merge(subway_node, "Subway", "name")
#         relationship = Relationship(house_node, "NEAR_SUBWAY", subway_node)
#         graph.create(relationship)

#     # 創建與bus的關聯
#     if row[8]:
#         bus_node = Node("Bus", name=row[8])
#         graph.merge(bus_node, "Bus", "name")
#         relationship = Relationship(house_node, "NEAR_BUS", bus_node)
#         graph.create(relationship)

# # 創建House之間的關係（這裡假設有某種鄰近關係）
# # 例如，根據地理位置或其他條件創建鄰近關係
# for id1, house_node1 in house_nodes.items():
#     for id2, house_node2 in house_nodes.items():
#         if id1 != id2:  # 排除自己與自己的關係
#             # 假設條件是地址前5個字符相同，表示地址接近
#             price1 = house_node1.get("price")
#             price2 = house_node2.get("price")
#             if price1 == price2:
#                 relationship = Relationship(house_node1, "same price", house_node2)
#                 graph.create(relationship)

# for id1, house_node1 in house_nodes.items():
#     for id2, house_node2 in house_nodes.items():
#         if id1 != id2:  # 排除自己與自己的關係
#             # 假設條件是地址前5個字符相同，表示地址接近
#             pattern1 = house_node1.get("pattern")
#             pattern2 = house_node2.get("pattern")
#             if pattern1 == pattern2:
#                 relationship = Relationship(house_node1, "same pattern", house_node2)
#                 graph.create(relationship)

# for id1, house_node1 in house_nodes.items():
#     for id2, house_node2 in house_nodes.items():
#         if id1 != id2:  # 排除自己與自己的關係
#             # 假設條件是地址前5個字符相同，表示地址接近
#             size1 = house_node1.get("size")
#             size2 = house_node2.get("size")
#             if size1 == size2:
#                 relationship = Relationship(house_node1, "same size", house_node2)
#                 graph.create(relationship)

# for id1, house_node1 in house_nodes.items():
#     for id2, house_node2 in house_nodes.items():
#         if id1 != id2:  # 排除自己與自己的關係
#             # 假設條件是地址前5個字符相同，表示地址接近
#             layer1 = house_node1.get("layer")
#             layer2 = house_node2.get("layer")
#             if layer1 == layer2:
#                 relationship = Relationship(house_node1, "same layer", house_node2)
#                 graph.create(relationship)    

# for id1, house_node1 in house_nodes.items():
#     for id2, house_node2 in house_nodes.items():
#         if id1 != id2:  # 排除自己與自己的關係
#             # 假設條件是地址前5個字符相同，表示地址接近
#             type1 = house_node1.get("type")
#             type2 = house_node2.get("type")
#             if type1 == type2:
#                 relationship = Relationship(house_node1, "same type", house_node2)
#                 graph.create(relationship)           

# # 關閉MySQL連接
# mysql_conn.close()

from mysql.connector import connect, Error
from py2neo import Graph, Node, Relationship
import time

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
    exit()

# 重試連接Neo4j的函數
def connect_to_neo4j(retries=5, wait=2):
    for attempt in range(retries):
        try:
            graph = Graph("bolt://localhost:7687", auth=("neo4j", "12345678"))
            print("Neo4j connection established.")
            return graph
        except Exception as e:
            print(f"Attempt {attempt + 1} failed: {e}")
            time.sleep(wait)
    print("Failed to connect to Neo4j after multiple attempts.")
    exit()

# 連接到Neo4j數據庫
graph = connect_to_neo4j()

# 從MySQL數據庫中抓取資料
query = "SELECT hid, pattern, layer, type, price, size, address, subway, bus FROM housedetail"
with mysql_conn.cursor() as cursor:
    cursor.execute(query)
    result = cursor.fetchall()

# 創建House節點並導入Neo4j
house_nodes = {}
for row in result:
    house_node = Node(
        "House",
        hid=row[0],
        pattern=row[1],
        layer=row[2],
        type=row[3],
        price=row[4],
        size=row[5],
        address=row[6]
    )
    graph.create(house_node)
    house_nodes[row[0]] = house_node  # 保存節點以便後續使用

    # 創建與subway的關聯
    if row[7]:
        subway_node = Node("Subway", name=row[7])
        graph.merge(subway_node, "Subway", "name")
        relationship = Relationship(house_node, "NEAR_SUBWAY", subway_node)
        graph.create(relationship)

    # 創建與bus的關聯
    if row[8]:
        bus_node = Node("Bus", name=row[8])
        graph.merge(bus_node, "Bus", "name")
        relationship = Relationship(house_node, "NEAR_BUS", bus_node)
        graph.create(relationship)

# 創建House之間的關係的函數
def create_relationships(house_nodes, attribute, relation_type):
    for id1, house_node1 in house_nodes.items():
        for id2, house_node2 in house_nodes.items():
            if id1 != id2:
                if house_node1[attribute] == house_node2[attribute]:
                    relationship = Relationship(house_node1, relation_type, house_node2)
                    graph.create(relationship)

# 創建House之間的關係
attributes_relations = [
    ("price", "SAME_PRICE"),
    ("pattern", "SAME_PATTERN"),
    ("size", "SAME_SIZE"),
    ("layer", "SAME_LAYER"),
    ("type", "SAME_TYPE")
]

for attribute, relation_type in attributes_relations:
    create_relationships(house_nodes, attribute, relation_type)

print("House relationships created.")

# 關閉MySQL連接
mysql_conn.close()

