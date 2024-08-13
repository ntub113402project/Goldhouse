import json
import os
import re

input_path = r"C:\Users\user\OneDrive\桌面\Goldhouse\web_crawler\test3\detail.json"
output_path = r"C:\Users\user\OneDrive\桌面\subway_and_bus.json"

with open(input_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

def clean_position_info(info_list):
    cleaned_info = []
    for info in info_list:
        cleaned = re.sub(r'距|(\d+公尺)', '', info).strip()
        cleaned_info.append(cleaned)
    return cleaned_info

processed_data = []

for item in data:
    new_item = {"hid": item["hid"]}
    if "positionround" in item:
        if "subway" in item["positionround"]:
            new_item["subway"] = clean_position_info(item["positionround"]["subway"])
        if "bus" in item["positionround"]:
            new_item["bus"] = clean_position_info(item["positionround"]["bus"])
    processed_data.append(new_item)

with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(processed_data, f, ensure_ascii=False, indent=4)

print(f"{output_path}")
