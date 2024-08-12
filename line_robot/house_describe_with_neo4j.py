#連接neo4j的房屋資訊提取
#pip install py2neo

from py2neo import Graph

graph = Graph("bolt://localhost:7687", auth=("neo4j", "12345678"))

def generate_description(hid):
    query = f"""
    MATCH (h:Property {{hid: '{hid}'}})
    OPTIONAL MATCH (h)-[:NEAR_STORE]->(s:Store)
    RETURN h, collect(s) as stores
    """
    result = graph.run(query).data()

    if not result:
        return "未找到與該HID相關的房屋資料。"

    house_info = result[0]['h']
    stores = result[0]['stores']
    
    descriptions = []

    if house_info.get("address"):
        descriptions.append(f"房屋地址位於{house_info['address']}。")
    if house_info.get("type"):
        descriptions.append(f"該房屋類型為{house_info['type']}。")
    if house_info.get("pattern"):
        descriptions.append(f"房屋格局為{house_info['pattern']}。")
    if house_info.get("size"):
        descriptions.append(f"房屋大小為{house_info['size']}坪。")
    if house_info.get("layer"):
        descriptions.append(f"樓層為{house_info['layer']}。")
    if house_info.get("price"):
        descriptions.append(f"房屋租金為{house_info['price']}元。")
    if house_info.get("subway"):
        descriptions.append(f"距離最近的地鐵站為{house_info['subway']}。")
    if house_info.get("bus"):
        descriptions.append(f"附近的公車站包括{house_info['bus']}。")

    if stores:
        store_names = [store.get('name') for store in stores if store.get('name')]
        if store_names:
            descriptions.append(f"附近有以下店家：{', '.join(store_names)}。")

    return " ".join(descriptions)

hid = input("請輸入HID：")
description = generate_description(hid)
print(description)