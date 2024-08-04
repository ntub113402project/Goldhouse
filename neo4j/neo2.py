from mysql.connector import connect, Error
from py2neo import Graph, Node, Relationship
import time

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

# 创建或获取节点的函数
def get_or_create_node(label, properties):
    node = graph.nodes.match(label, **properties).first()
    if not node:
        node = Node(label, **properties)
        graph.create(node)
        print(f"Node {properties} created in label {label}.")
    else:
        print(f"Node {properties} already exists in label {label}.")
    return node

# 创建关系的函数
def create_relationship(node1, rel_type, node2):
    relationship = Relationship(node1, rel_type, node2)
    graph.create(relationship)
    print(f"Relationship {rel_type} created between {node1} and {node2}.")

def get_subway_station_node(station_name):
    return get_or_create_node('SubwayStation', {'name': station_name})

# 创建或获取公交站节点的函数
def get_bus_station_node(station_name):
    return get_or_create_node('BusStation', {'name': station_name})


# 将MySQL数据插入到Neo4j
for row in rows:
    # 创建House节点
    house_properties = {
        'hid': row[0],
        'pattern': row[1],
        'size': row[2],
        'layer': row[3],
        'type': row[4],
        'price': row[5],
        'adress': row[6],
        
    }
    house_node = get_or_create_node('House', house_properties)
    
    if row[7]:  # 检查subway字段是否为None
        subway_info = row[7].split('距')
        subway_station_name = subway_info[0].strip()
        subway_distance = subway_info[1].split('公尺')[0] if len(subway_info) > 1 else '未知'
        
        subway_properties = {
            'name': subway_station_name,
            'distance': subway_distance
        }
        subway_node = get_subway_station_node(subway_station_name)
        create_relationship(house_node, 'NEAR_SUBWAY', subway_node)

    # 处理Bus信息
    if row[8]:  # 检查bus字段是否为None
        bus_stops = row[8].split(',')
        for bus_stop in bus_stops:
            bus_info = bus_stop.strip().split('距')
            bus_station_name = bus_info[0].strip()
            bus_distance = bus_info[1].split('公尺')[0] if len(bus_info) > 1 else '未知'
            
            bus_properties = {
                'name': bus_station_name,
                'distance': bus_distance
            }
            bus_node = get_bus_station_node(bus_station_name)
            create_relationship(house_node, 'NEAR_BUS', bus_node)

print("Data import to Neo4j completed.")

# 关闭连接
mysql_cursor.close()
mysql_conn.close()
print("All connections closed.")
