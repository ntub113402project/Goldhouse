import json

input_path = r"C:\Users\user\OneDrive\桌面\detail.json"
output_path = r"C:\Users\user\OneDrive\桌面\available_devices.json"

with open(input_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

processed_data = []

for item in data:
    new_item = {"hid": item["hid"]}
    
    # 提取所有 avaliable 为 true 的设备
    if "servicelist" in item:
        available_devices = [device["device"] for device in item["servicelist"] if device["avaliable"]]
        new_item["available_devices"] = available_devices
    
    processed_data.append(new_item)

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(processed_data, f, ensure_ascii=False, indent=4)

print(f"{output_path}")
