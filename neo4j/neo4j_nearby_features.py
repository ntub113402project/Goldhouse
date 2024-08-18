import json
from py2neo import Graph, Node, Relationship
import time
import os

# 连接到Neo4j数据库的函数，带有重试机制
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

# JSON文件路径
json_file_path = r'C:\Users\ntubgoldhouse\Desktop\Goldhouse\ner\nearby_ORG_cleaned_2.json'

# 检查文件是否存在
if not os.path.exists(json_file_path):
    print(f"File not found: {json_file_path}")
    exit(1)

# 读取JSON文件
try:
    with open(json_file_path, 'r', encoding='utf-8') as f:
        store_data = json.load(f)
except json.JSONDecodeError as e:
    print(f"Error reading JSON file: {e}")
    exit(1)

# 处理数据并写入Neo4j
try:
    for entry in store_data:
        hid = entry.get('hid')
        stores = entry.get('store', [])

        if not isinstance(stores, list):
            print(f"Skipping property {hid} because 'store' is not a list.")
            continue

        # 查找对应的Property节点
        property_node = graph.nodes.match("Property", hid=hid).first()
        if not property_node:
            print(f"Property {hid} not found in the database.")
            continue

        # 创建或获取每个Store节点并创建关系
        for store in stores:
            store_node = Node("Store", name=store)
            graph.merge(store_node, "Store", "name")  # 使用 merge 避免重复创建
            relationship = Relationship(property_node, "NEAR_STORE", store_node)
            graph.create(relationship)
            print(f"Created relationship: {hid} -> {store} (Store)")

    print("All store data successfully integrated into Neo4j.")
except Exception as e:
    print(f"Error processing data: {e}")
