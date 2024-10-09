import json

# 讀取 data.json
with open('data.json', encoding='utf-8') as f:
    datalist = json.load(f)

# 創建一個列表來保存所有 result_list
all_results = []

for data in datalist:
    # 提取需要的欄位數據
    hid = data.get("hid")
    price = data["houseinfo"].get("price")
    size = data["houseinfo"].get("size")
    layer = data["houseinfo"].get("layer")

    # 將這些欄位組成列表
    result_list = [hid, price, size, layer]

    # 將 result_list 添加到 all_results 列表中
    all_results.append(result_list)

# 將 all_results 寫入 data2.json
with open('data2.json', 'w', encoding='utf-8') as f:
    json.dump(all_results, f, ensure_ascii=False, indent=4)

print("Data saved to data2.json")
