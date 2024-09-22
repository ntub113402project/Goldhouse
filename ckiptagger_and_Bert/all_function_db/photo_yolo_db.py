import os
import clip
import torch
import json
from PIL import Image
from transformers import BertTokenizer, BertModel
from ultralytics import YOLO

# 加載 CLIP 模型
device = "cuda" if torch.cuda.is_available() else "cpu"
clip_model, preprocess = clip.load('ViT-B/32', device=device)

# 加載 BERT 模型與分詞器
tokenizer = BertTokenizer.from_pretrained('bert-base-chinese')
bert_model = BertModel.from_pretrained('bert-base-chinese').to(device)

# 初始化 YOLO 模型
yolo_model = YOLO("yolov8n.pt")

def detect_and_describe_image(image_path):
    # 使用 YOLO 偵測物件
    yolo_results = yolo_model(image_path)
    yolo_labels = [yolo_model.names[int(cls)] for cls in yolo_results[0].boxes.cls.tolist()]

    # 使用 CLIP 生成整體圖片描述
    image = preprocess(Image.open(image_path)).unsqueeze(0).to(device)
    clip_features = clip_model.encode_image(image)
    clip_text = clip_model.decode(clip_features)

    # 分詞並使用 BERT 處理 CLIP 的輸出
    inputs = tokenizer(clip_text.split(), return_tensors="pt", padding=True).to(device)
    bert_outputs = bert_model(**inputs)
    bert_features = bert_outputs.last_hidden_state.mean(dim=1).tolist()

    return {
        "image": os.path.basename(image_path),
        "yolo_objects": yolo_labels,
        "clip_description": clip_text,
        "bert_features": bert_features
    }

def process_folder(folder_path):
    results = []
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(('png', 'jpg', 'jpeg')):
                image_path = os.path.join(root, file)
                image_result = detect_and_describe_image(image_path)
                results.append(image_result)
    return results

def main():
    base_folder = "C:\\Users\\user\\OneDrive\\桌面\\gold_house"
    output_path = "C:\\Users\\user\\OneDrive\\桌面\\image_features.json"
    all_results = []

    # 處理每個 HID 資料夾
    for hid in os.listdir(base_folder):
        folder_path = os.path.join(base_folder, hid)
        if os.path.isdir(folder_path):
            hid_results = process_folder(folder_path)
            all_results.append({
                "hid": hid,
                "images": hid_results
            })

    # 保存結果到 JSON
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(all_results, f, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    main()
