import json
import re

input_file_path = "C:\\Users\\user\\OneDrive\\桌面\\Goldhouse\\ner\\nearby_ORG.json"
output_file_path = "C:/Users/user/OneDrive/桌面/nearby_ORG_cleaned.json"

with open(input_file_path, "r", encoding="utf-8") as file:
    data = json.load(file)

custom_suffixes = [
    "公園", "學校", "醫院", "機構", "市", "店", "超市", "站", "中心", "街", 
    "市場", "公司", "高中", "小學", "幼兒園", "大學", "學校", "中心", "診所", 
    "醫院", "診所", "中心", "館", "局", "廣場", "院", "館", "中心", "場所", "廟", "堂"
]

def remove_english(text):
    return re.sub(r'[a-zA-Z]', '', text)

def filter_no_spaces(names):
    return [name for name in names if ' ' not in name and name.strip() != ""]

def filter_by_suffix(names, suffixes):
    return [name for name in names if any(name.endswith(suffix) for suffix in suffixes)]

for item in data:
    if 'store' in item:
        item['store'] = [remove_english(store) for store in item['store']]
        item['store'] = filter_no_spaces(item['store'])
        item['store'] = filter_by_suffix(item['store'], custom_suffixes)

with open(output_file_path, "w", encoding="utf-8") as file:
    json.dump(data, file, ensure_ascii=False, indent=4)

print(f"已將處理後的數據保存至 {output_file_path}")
