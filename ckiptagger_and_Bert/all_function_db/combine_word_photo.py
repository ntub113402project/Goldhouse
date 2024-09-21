import json

# 載入 JSON 檔案
with open("C:\\Users\\user\\OneDrive\\桌面\\image_features_1.json", 'r', encoding='utf-8') as f:
    data = json.load(f)

# 使用集合來檢查是否有重複的 hid
seen = set()
duplicates = set()

for item in data:
    hid = item.get("hid")
    if hid in seen:
        duplicates.add(hid)
    else:
        seen.add(hid)

# 輸出結果
if duplicates:
    print(f"重複的hid有: {duplicates}")
else:
    print("沒有重複的hid")
