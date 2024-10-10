import json

# 定义字段与描述的模板
fields_to_description = {
    "pattern": "房屋格局為 {value}。",
    "size": "房屋大小為 {value}。",
    "layer": "樓層/最高樓層為 {value}。",
    "type": "房屋類型為 {value}。",
    "price": "房屋租金為 {value} 元。"
}

def generate_description(house_info):
    descriptions = []
    
    # 處理房屋基本信息
    for field, template in fields_to_description.items():
        if house_info["houseinfo"].get(field):
            descriptions.append(template.format(value=house_info["houseinfo"][field]))
    
    # 處理附加設備
    devices = [item["device"] for item in house_info["servicelist"] if item["avaliable"]]
    if devices:
        descriptions.append(f"提供的附加設備有：{', '.join(devices)}。")
    
    # 填充附近交通信息描述
    position_info = house_info.get("positionround", {})
    address = position_info.get("address", "")
    subway_stations = position_info.get("subway", [])
    bus_stations = position_info.get("bus", [])
    
    if address:
        descriptions.append(f"房屋地址位於 {address}。")
    if subway_stations:
        descriptions.append(f"附近的捷運站有：{', '.join(subway_stations)}。")
    if bus_stations:
        descriptions.append(f"附近的公車站有：{', '.join(bus_stations)}。")
    
    return "\n".join(descriptions) if descriptions else "未找到相關特徵資料。"

# 示例使用
def main():
    # 读取 JSON 文件
    json_path = r"C:\Users\user\OneDrive\桌面\testdata.json"
    
    try:
        with open(json_path, "r", encoding="utf-8") as file:
            data = json.load(file)
            description = generate_description(data)
            print(description)
    
    except json.JSONDecodeError as e:
        print(f"JSON 解析錯誤: {e}")
    except FileNotFoundError:
        print(f"文件未找到：{json_path}")

if __name__ == "__main__":
    main()
