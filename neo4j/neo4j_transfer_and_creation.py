from mysql.connector import connect, Error
from py2neo import Graph, Node, Relationship
import time
import re

# 连接到MySQL数据库
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

# 重试连接Neo4j的函数
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

# 查询MySQL数据
try:
    mysql_cursor = mysql_conn.cursor()
    mysql_cursor.execute("SELECT hid, pattern, size, layer, type, price, address, subway, bus FROM new_housedetail")
    rows = mysql_cursor.fetchall()
    print("MySQL data successfully retrieved.")
except Error as e:
    print(f"Error: {e}")
    mysql_conn.close()
    exit()

# 定义价格和大小范围
price_ranges = [
    (0, 5000),
    (5000, 10000),
    (10000, 15000),
    (15000, 20000),
    (20000, 25000),
    (25000, 30000),
    (30000, float('inf'))  # Use float('inf') for an open-ended range
]

size_ranges = [
    (0, 5),
    (5, 10),
    (10, 15),
    (15, 20),
    (20, 25),
    (25, 30)
]

def parse_size(size_str):
    match = re.match(r"(\d+)", size_str)
    if match:
        return int(match.group(1))
    return None

# 处理数据并写入Neo4j
try:
    for row in rows:
        hid, pattern, size_str, layer, type, price, address, subway, bus = row
        size = parse_size(size_str)
        
        if size is None:
            print(f"Skipping property {hid} due to unparseable size: {size_str}")
            continue

        # 创建房屋节点
        property_node = Node("Property", hid=hid, pattern=pattern, size=size, layer=layer, type=type, price=price, address=address, subway=subway, bus=bus)
        graph.create(property_node)
        print(f"Created Property node: {hid}")

        # 创建物件类型节点
        type_node = Node("Type", name=type)
        graph.merge(type_node, "Type", "name")  # 使用 merge 避免重複創建
        print(f"Ensured Type node: {type}")

        # 创建物件類型（pattern）節點
        pattern_node = Node("Pattern", name=pattern)
        graph.merge(pattern_node, "Pattern", "name")  # 使用 merge 避免重複創建
        print(f"Ensured Pattern node: {pattern}")

        # 根据价格创建价格范围节点
        for min_price, max_price in price_ranges:
            if min_price <= price < max_price:
                price_range_name = f"{min_price}~{max_price}"
                price_node = Node("PriceRange", name=price_range_name)
                graph.merge(price_node, "PriceRange", "name")  # 使用 merge 避免重複創建
                print(f"Ensured PriceRange node: {price_range_name}")

                # 创建与价格范围的关联
                price_relationship = Relationship(property_node, "IN_PRICE_RANGE", price_node)
                graph.create(price_relationship)
                print(f"Created relationship: {hid} -> {price_range_name} (PriceRange)")
                break

        # 根据大小创建大小范围节点
        for min_size, max_size in size_ranges:
            if min_size <= size < max_size:
                size_range_name = f"{min_size}~{max_size}"
                size_node = Node("SizeRange", name=size_range_name)
                graph.merge(size_node, "SizeRange", "name")  # 使用 merge 避免重複創建
                print(f"Ensured SizeRange node: {size_range_name}")

                # 创建与大小范围的关联
                size_relationship = Relationship(property_node, "IN_SIZE_RANGE", size_node)
                graph.create(size_relationship)
                print(f"Created relationship: {hid} -> {size_range_name} (SizeRange)")
                break

        # 创建关联
        property_type_relationship = Relationship(property_node, "HAS_TYPE", type_node)
        graph.create(property_type_relationship)
        print(f"Created relationship: {hid} -> {type} (Type)")

        property_pattern_relationship = Relationship(property_node, "HAS_PATTERN", pattern_node)
        graph.create(property_pattern_relationship)
        print(f"Created relationship: {hid} -> {pattern} (Pattern)")

    print("All data successfully written to Neo4j.")
except Exception as e:
    print(f"Error: {e}")

# 关闭MySQL连接
mysql_cursor.close()
mysql_conn.close()
print("MySQL connection closed.")
