import json
import re

input_file_path = "C:\\Users\\user\\OneDrive\\桌面\\Goldhouse\\ner\\nearby_ORG.json"
output_file_path = "C:/Users/user/OneDrive/桌面/nearby_ORG_cleaned.json"

# Load data from file
with open(input_file_path, "r", encoding="utf-8") as file:
    data = json.load(file)

# Custom suffixes for organizations
custom_suffixes = [
    "公園", "學校", "醫院", "機構", "市", "店", "超市", "站", "中心", "街",
    "市場", "公司", "高中", "小學", "幼兒園", "大學", "學院", "診所", "館",
    "局", "廣場", "院", "場所", "廟", "堂"
]

# Specific exclusions
exclusions = ["不動產", "加盟店", "直營店", "元大花廣圓頂世紀館", "住都中心", "台北聯勝租賃部"]

def preprocess_names(names):
    split_patterns = {
        "台灣大學醫學院台北商業大學師範大學": ["台灣大學醫學院", "台北商業大學", "師範大學"],
        "北商台大北科": ["北商", "台大", "北科"],
        "東吳大學文化大學": ["東吳大學", "文化大學"],
        "特力屋北市商銘傳大學": ["特力屋", "北市商", "銘傳大學"],
        "台北商業大學醫療機構": ["台北商業大學","醫療機構"],
        "全家超商醫療機構": ["全家超商", "醫療機構"],
        "劍潭國小百齡高中": ["劍潭國小","百齡高中"],
        "家樂福全聯蝦皮店": ["家樂福","全聯","蝦皮"],
        "台灣銀行第一銀行花旗銀行合庫華南郵局": ["台灣銀行","第一銀行","花旗銀行","合庫","華南","郵局"],
        "聯頂好家樂福銀行郵局": ["全聯","頂好","家樂福","郵局","銀行"],
        "聯家樂福晴光商圈郵局": ["全聯","家樂福","晴光商圈","郵局"],
        "家樂福郵局": ["家樂福","郵局"],
        "南近郵局": ["郵局"]
    }
    processed_names = []
    for name in names:
        for pattern, splits in split_patterns.items():
            if pattern in name:
                processed_names.extend(splits)
                break
        else:
            processed_names.append(name)
    return processed_names

def remove_duplicates_and_manage_empty(data):
    for item in data:
        # 轉換列表為集合以去除重複
        unique_stores = set(item.get('store', []))

        # 如果存在“醫院”，則確保不會有“醫療機構”
        if "醫院" in unique_stores:
            unique_stores.discard("醫療機構")
        else:
            # 將所有“醫療機構”替換為“醫院”
            if "醫療機構" in unique_stores:
                unique_stores.discard("醫療機構")
                unique_stores.add("醫院")

        # 移除'學校'如果存在特定教育后缀
        if "學校" in unique_stores and any(sub in unique_stores for sub in ["高中", "小學", "幼兒園", "大學", "學院"]):
            unique_stores.remove("學校")

        # 將集合轉換回列表或者如果為空則為None
        item['store'] = list(unique_stores) if unique_stores else None

    return data


# Save data to file
with open(output_file_path, "w", encoding="utf-8") as file:
    json.dump(data, file, ensure_ascii=False, indent=4)

print(f"Processed data saved to {output_file_path}")
