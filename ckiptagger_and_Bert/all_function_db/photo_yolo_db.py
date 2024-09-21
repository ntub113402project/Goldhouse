import os
import json
import numpy as np
from ultralytics import YOLO
from PIL import Image
from collections import Counter

# 初始化 YOLO 模型
yolo_model = YOLO("yolov8n.pt")

# 使用 YOLO 偵測物件
def detect_objects(image_path):
    results = yolo_model(image_path)
    image = Image.open(image_path)
    
    # 使用 names 屬性來獲取物品名稱，而非索引
    labels = [yolo_model.names[int(cls)] for cls in results[0].boxes.cls.tolist()]  # YOLO 偵測到的物件名稱
    return labels, image

# 提取圖片的主色
def get_dominant_color(image):
    try:
        image = image.resize((50, 50))
        pixels = np.array(image)
        
        if pixels.ndim == 3 and pixels.shape[2] == 3:
            pixels = pixels.reshape(-1, 3)  # 將圖像像素展開
        else:
            print("不是 RGB 格式，跳過此圖片")
            return None
        
        counter = Counter(map(tuple, pixels))
        dominant_color = counter.most_common(1)[0][0]
        return tuple(map(int, dominant_color))  # 確保轉換為整數類型
    except Exception as e:
        print(f"提取主要顏色時出錯: {e}，跳過此圖片")
        return None

# 提取圖片描述（紀錄物品和顏色）
def generate_descriptions(image, labels):
    descriptions = []
    dominant_color = get_dominant_color(image)
    
    if dominant_color is not None:
        color_text = f"RGB({dominant_color[0]}, {dominant_color[1]}, {dominant_color[2]})"
        
        for label in labels:
            descriptions.append({
                "object_label": label,  # 正確顯示物品名稱
                "color_text": color_text  # 物品顏色
            })
    else:
        print("無法提取主要顏色，跳過此圖片。")
    
    return descriptions

# 提取圖片特徵並儲存至JSON
def extract_image_features(hid, image_folder):
    hid_folder = os.path.join(image_folder, str(hid))
    if not os.path.exists(hid_folder):
        print(f"跳過沒有圖片的 HID: {hid}")
        return None

    images = os.listdir(hid_folder)
    if not images:
        print(f"跳過沒有圖片的 HID: {hid}")
        return None
    
    image_features = []
    for img in images:
        image_path = os.path.join(hid_folder, img)
        labels, image = detect_objects(image_path)
        VP_image = generate_descriptions(image, labels)

        image_features.append({
            "image_name": img,
            "objects": VP_image
        })
    
    return {
        "hid": hid,
        "VP_images": image_features
    }

# 提取前五筆圖片特徵並儲存至 JSON
def extract_and_save_image_features(image_folder, output_image_json):
    image_features = []
    hids = os.listdir(image_folder)

    for hid in hids:
        hid_folder_path = os.path.join(image_folder, hid)
        if os.path.isdir(hid_folder_path):
            image_feature = extract_image_features(hid, image_folder)
            if image_feature:
                image_features.append(image_feature)
            print(f"已經處理完 HID: {hid}")
    
    if image_features:
        print(f"提取到的圖片數量: {len(image_features)}")
        print(f"正在寫入文件: {output_image_json}")

        os.makedirs(os.path.dirname(output_image_json), exist_ok=True)
        with open(output_image_json, 'w', encoding='utf-8') as f:
            json.dump(image_features, f, ensure_ascii=False, indent=4)
        print(f"圖片特徵已存入 {output_image_json}")
    else:
        print("沒有提取任何圖片，無法寫入 JSON 文件。")

def main():
    image_folder = "C:\\Users\\user\\OneDrive\\桌面\\gold_house"
    output_image_json = "C:\\Users\\user\\OneDrive\\桌面\\image_features.json"
    
    extract_and_save_image_features(image_folder, output_image_json)

if __name__ == "__main__":
    main()
