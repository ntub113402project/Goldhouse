import os
import json

def merge_text_and_image_features(text_json_path, image_json_path, output_json_path):
    # 讀取文字特徵的 JSON 檔案
    with open(text_json_path, 'r', encoding='utf-8') as f:
        text_data = json.load(f)

    # 讀取圖片特徵的 JSON 檔案
    with open(image_json_path, 'r', encoding='utf-8') as f:
        image_data = json.load(f)

    # 根據 text_data 中的 hid，篩選出有相同 hid 的圖片特徵
    image_features_by_hid = {item['hid']: item['VP_images'] for item in image_data if item['hid'] in {text_item['hid'] for text_item in text_data}}

    # 將圖片特徵合併到相應的文字特徵中
    for text_item in text_data:
        hid = text_item.get('hid')
        if hid in image_features_by_hid:
            text_item['VP_images'] = image_features_by_hid[hid]
        else:
            text_item['VP_images'] = []  # 若無對應圖片，則設置為空列表

    # 將合併後的資料寫入到新的 JSON 檔案
    with open(output_json_path, 'w', encoding='utf-8') as f:
        json.dump(text_data, f, ensure_ascii=False, indent=4)

    print(f"已經將結果存到 {output_json_path}")

def main():
    # 定義 JSON 檔案的路徑
    text_json_path = "C:\\Users\\user\\OneDrive\\桌面\\text_features_1.json"
    image_json_path = "C:\\Users\\user\\OneDrive\\桌面\\image_features_1.json"
    output_json_path = "C:\\Users\\user\\OneDrive\\桌面\\merged_features_1.json"

    # 合併 JSON 檔案
    merge_text_and_image_features(text_json_path, image_json_path, output_json_path)

if __name__ == "__main__":
    main()
