import torch
from PIL import Image
from transformers import CLIPProcessor, CLIPModel
from ultralytics import YOLO
from collections import Counter
import numpy as np
from sklearn.metrics import pairwise_distances
import os
import glob

yolo_model = YOLO("yolov8n.pt")  # 使用適當的 YOLOv8 模型權重

clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")

# 偵測物件
def detect_objects(image_path):
    results = yolo_model(image_path)
    objects = results[0].boxes.xyxy.cpu().numpy()
    return objects, results

# 提取主要顏色
def get_dominant_color(image):
    image = image.resize((50, 50))  
    pixels = np.array(image).reshape(-1, 3)
    counter = Counter(map(tuple, pixels))
    dominant_color = counter.most_common(1)[0][0]
    return dominant_color

# 使用 CLIP 生成英文描述
def generate_clip_description(image, objects):
    descriptions = []
    for obj in objects:
        x1, y1, x2, y2 = map(int, obj[:4]) 
        cropped_image = image.crop((x1, y1, x2, y2))
        dominant_color = get_dominant_color(cropped_image)
        color_name = f"{dominant_color}"
        
        inputs = clip_processor(images=cropped_image, return_tensors="pt")
        with torch.no_grad():
            image_features = clip_model.get_image_features(**inputs)

        # 定義一組預設的文本描述，包含顏色信息
        texts = [
            f"a {color_name} room", f"a {color_name} chair", f"a {color_name} table", f"a {color_name} bed",
            f"a {color_name} lamp", f"a {color_name} window", f"a {color_name} door", f"a {color_name} sofa",
            f"a {color_name} bookshelf", f"a {color_name} desk", f"a {color_name} cabinet", f"a {color_name} dresser",
            f"a {color_name} wardrobe", f"a {color_name} rug", f"a {color_name} picture frame", f"a {color_name} TV",
            f"a {color_name} computer", f"a {color_name} plant", f"a {color_name} clock", f"a {color_name} mirror"
        ]
        text_inputs = clip_processor(text=texts, return_tensors="pt", padding=True)
        text_features = clip_model.get_text_features(**text_inputs)

        # 計算圖像特徵和文本特徵之間的相似度
        similarities = torch.nn.functional.cosine_similarity(image_features, text_features)
        best_match = similarities.argmax().item()
        descriptions.append((texts[best_match], dominant_color))
    return descriptions

# 計算描述相似度，包含顏色比較
def calculate_similarity(desc1, desc2):
    similarities = []
    for d1, color1 in desc1:
        for d2, color2 in desc2:
            text_similarity = 1 if d1.split(" ")[1:] == d2.split(" ")[1:] else 0  # 忽略顏色部分進行文本相似度比較
            color_similarity = 1 - pairwise_distances([color1], [color2], metric='cosine')[0][0]  # 使用cosine相似度比較顏色
            combined_similarity = 0.5 * text_similarity + 0.5 * color_similarity  # 結合文本和顏色相似度
            similarities.append(combined_similarity)
    return similarities

def process_folder(folder_path):
    image_paths = glob.glob(os.path.join(folder_path, "*.jpg"))
    all_descriptions = {}
    for image_path in image_paths:
        objects, yolo_results = detect_objects(image_path)
        image = Image.open(image_path)
        descriptions = generate_clip_description(image, objects)
        all_descriptions[image_path] = descriptions
        print(f"Processed {image_path}")
    return all_descriptions

folder1 = "C:\\Users\\user\\OneDrive\\桌面\\爬蟲\\gold_house\\8713071 - 複製"
folder2 = "C:\\Users\\user\\OneDrive\\桌面\\爬蟲\\gold_house\\8713071"

descriptions1 = process_folder(folder1)
descriptions2 = process_folder(folder2)

all_similarities = []
for path1, desc1 in descriptions1.items():
    for path2, desc2 in descriptions2.items():
        if len(desc1) > 0 and len(desc2) > 0:
            similarities = calculate_similarity(desc1, desc2)
            similarity_score = sum(similarities) / max(len(desc1), len(desc2))
            all_similarities.append((path1, path2, similarity_score, desc1, desc2))

# 設定閾值，判斷兩個資料夾內圖像相似程度
image_threshold = 0.8
folder_threshold = 0.6
similar_count = 0

if len(all_similarities) > 0:
    for path1, path2, score, desc1, desc2 in all_similarities:
        print(f"Comparing {path1} and {path2}")
        print(f"CLIP Descriptions for {path1}: {desc1}")
        print(f"CLIP Descriptions for {path2}: {desc2}")
        print(f"Similarity Score: {score:.2f}")
        if score > image_threshold:
            print("The images are likely from the same room.")
            similar_count += 1
        else:
            print("The images are likely from different rooms.")
        print()

    folder_similarity_ratio = similar_count / len(all_similarities)
    print(f"Similarity ratio between the two folders: {folder_similarity_ratio:.2f}")
    if folder_similarity_ratio > folder_threshold:
        print("The folders are likely from the same house.")
    else:
        print("The folders are likely from different houses.")
else:
    print("No similarities found between the two folders.")
