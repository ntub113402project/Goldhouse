import json
from py2neo import Graph, Node, Relationship
import time
import os

# 假设你已经连接到了Neo4j数据库
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

# 连接到Neo4j数据库

graph = connect_to_neo4j()

# 读取JSON文件
json_file_path = r'C:\Users\ntubgoldhouse\Desktop\Goldhouse\neo4j\subway_and_bus.json'

# 檢查文件是否存在
if not os.path.exists(json_file_path):
    print(f"File not found: {json_file_path}")
    exit(1)

# 讀取 JSON 文件
with open(json_file_path, 'r', encoding='utf-8') as f:
    data = json.load(f)



# 处理数据并写入Neo4j
try:
    for entry in data:
        hid = entry.get('hid')
        subways = entry.get('subway', [])
        buses = entry.get('bus', [])

        # 查找对应的Property节点
        property_node = graph.nodes.match("Property", hid=hid).first()
        if not property_node:
            print(f"Property {hid} not found in the database.")
            continue

        # 创建或获取每个Subway节点并创建关系
        for subway_station in subways:
            subway_node = Node("Subway", name=subway_station)
            graph.merge(subway_node, "Subway", "name")  # 使用 merge 避免重复创建
            relationship = Relationship(property_node, "NEAR_SUBWAY", subway_node)
            graph.create(relationship)
            print(f"Created relationship: {hid} -> {subway_station} (Subway)")

        # 创建或获取每个Bus节点并创建关系
        for bus_stop in buses:
            bus_node = Node("Bus", name=bus_stop)
            graph.merge(bus_node, "Bus", "name")  # 使用 merge 避免重复创建
            relationship = Relationship(property_node, "NEAR_BUS", bus_node)
            graph.create(relationship)
            print(f"Created relationship: {hid} -> {bus_stop} (Bus)")

    print("All transportation data successfully integrated into Neo4j.")
except Exception as e:
    print(f"Error: {e}")
