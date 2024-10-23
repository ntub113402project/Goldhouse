import os
import json
import torch
import torch.nn.functional as F
from ckiptagger import WS, NER
from transformers import BertTokenizer, BertModel, CLIPProcessor, CLIPModel
from ultralytics import YOLO
from PIL import Image
from collections import Counter
import numpy as np
from concurrent.futures import ThreadPoolExecutor

# Initialize models
ws = WS("C:\\Users\\user\\OneDrive\\桌面\\data")
ner = NER("C:\\Users\\user\\OneDrive\\桌面\\data")
tokenizer = BertTokenizer.from_pretrained('bert-base-chinese')
bert_model = BertModel.from_pretrained('bert-base-chinese')
clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
yolo_model = YOLO("yolov8n.pt")

def get_bert_embedding(text):
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
    with torch.no_grad():
        outputs = bert_model(**inputs)
    return outputs.last_hidden_state[:, 0, :].squeeze()

def load_json(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return json.load(file)

def preprocess_data(items):
    for item in items:
        address_text = ' '.join([str(a).strip() for a in item['positionround'].get('address', [])])
        address_tokens = ws([address_text])
        item['address_emb'] = get_bert_embedding(' '.join(address_tokens[0]))
    return items

def apply_ner_filter(content_list):
    locations = []
    for content in content_list:
        # Tokenize content
        sentences = ws([content])
        # Apply NER
        ner_results = ner(sentences)
        # Extract locations based on NER tags
        for name, (ner_tag, _) in zip(sentences[0], ner_results[0]):
            if ner_tag == 'LOC':  # Extract locations
                locations.append(name)
    return locations

def cosine_similarity(tensor1, tensor2):
    return F.cosine_similarity(tensor1.unsqueeze(0), tensor2.unsqueeze(0)).item()

def device_similarity(devices1, devices2):
    common_devices = set(d1['device'] for d1 in devices1).intersection(set(d2['device'] for d2 in devices2))
    matched = sum(1 for d1 in devices1 for d2 in devices2 if d1['device'] == d2['device'] and d1['avaliable'] == d2['avaliable'])
    return matched / min(len(devices1), len(devices2)) >= 0.7

def compare_patterns(pattern1, pattern2):
    return (len(set(pattern1.split()).intersection(pattern2.split())) / min(len(pattern1.split()), len(pattern2.split()))) > 0.9

def compare_layers(layer1, layer2):
    layers1 = set(layer1.split('/'))
    layers2 = set(layer2.split('/'))
    return bool(layers1.intersection(layers2))

def find_text_similar_items(data):
    similar_items = set()  # 使用 set 來儲存避免重複的 pair
    n = len(data)
    for i in range(n):
        for j in range(i + 1, n):
            # 進行地址相似度比較
            address_similarity = cosine_similarity(data[i]['address_emb'], data[j]['address_emb']) > 0.9
            if address_similarity:
                # 如果地址相似，則進行其他屬性比對
                pattern_match = compare_patterns(data[i]['houseinfo']['pattern'], data[j]['houseinfo']['pattern'])
                size_match = compare_patterns(data[i]['houseinfo']['size'], data[j]['houseinfo']['size'])
                layer_match = compare_layers(data[i]['houseinfo']['layer'], data[j]['houseinfo']['layer'])
                device_match = device_similarity(data[i]['servicelist'], data[j]['servicelist'])
                
                # 當所有條件都符合時，記錄這對房屋，並保證順序一致 (min, max)
                if pattern_match and size_match and layer_match and device_match:
                    similar_items.add((min(data[i]['hid'], data[j]['hid']), max(data[i]['hid'], data[j]['hid'])))
    return list(similar_items)

def detect_objects(image_path):
    results = yolo_model(image_path)
    image = Image.open(image_path)
    objects = results[0].boxes.xyxy.cpu().numpy()
    return objects, image

def get_dominant_color(image):
    image = image.resize((50, 50))  
    pixels = np.array(image).reshape(-1, 3)
    counter = Counter(map(tuple, pixels))
    dominant_color = counter.most_common(1)[0][0]
    return dominant_color

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
        texts = [f"a {color_name} object"] * 20
        text_inputs = clip_processor(text=texts, return_tensors="pt", padding=True)
        text_features = clip_model.get_text_features(**text_inputs)
        similarities = F.cosine_similarity(image_features, text_features)
        best_match = similarities.argmax().item()
        descriptions.append((texts[best_match], dominant_color))
    return descriptions

def calculate_image_similarity(desc1, desc2):
    similarity_scores = []
    for d1, d2 in zip(desc1, desc2):
        text1, _ = d1
        text2, _ = d2
        text_emb1 = clip_processor(text=[text1], return_tensors="pt", padding=True)
        text_emb2 = clip_processor(text=[text2], return_tensors="pt", padding=True)
        text_features1 = clip_model.get_text_features(**text_emb1)
        text_features2 = clip_model.get_text_features(**text_emb2)
        cosine_sim = F.cosine_similarity(text_features1, text_features2).item()
        similarity_scores.append(cosine_sim)
    
    return sum(similarity_scores) / len(similarity_scores) if similarity_scores else 0

def process_image_similarity(img1, img2, threshold=0.5):
    image_path1, desc1 = img1
    image_path2, desc2 = img2
    return calculate_image_similarity(desc1, desc2) > threshold

def find_image_similar_items(text_similar_items, image_folder, threshold=0.6):
    similar_items = []
    
    with ThreadPoolExecutor() as executor:
        for hid1, hid2 in text_similar_items:
            images1 = os.listdir(os.path.join(image_folder, str(hid1)))
            images2 = os.listdir(os.path.join(image_folder, str(hid2)))
            
            # 使用多線程並行處理圖片相似度
            image_pairs = []
            for img1 in images1:
                image_path1 = os.path.join(image_folder, str(hid1), img1)
                objects1, image1 = detect_objects(image_path1)
                desc1 = generate_clip_description(image1, objects1)
                for img2 in images2:
                    image_path2 = os.path.join(image_folder, str(hid2), img2)
                    objects2, image2 = detect_objects(image_path2)
                    desc2 = generate_clip_description(image2, objects2)
                    image_pairs.append(((image_path1, desc1), (image_path2, desc2)))
            
            # 並行計算圖片相似度
            results = list(executor.map(lambda pair: process_image_similarity(pair[0], pair[1], threshold), image_pairs))
            if all(results):
                similar_items.append((hid1, hid2))
    
    return similar_items

def main():
    # 讀取資料並預處理
    json_data = load_json("C:\\Users\\user\\OneDrive\\桌面\\detail-複製.json")
    complete_data = preprocess_data(json_data)
    
    # 使用 NER 提取 content 中的地點
    for item in complete_data:
        content_list = item['remark']['content']
        locations = apply_ner_filter(content_list)
        if locations:
            item['location_emb'] = get_bert_embedding(' '.join(locations))
    
    # 文字相似度比對
    print("開始進行文字相似度比對...")
    text_similar_items = find_text_similar_items(complete_data)
    
    # 輸出文字相似度比對結果
    print("文字相似度比對結果:")
    for hid1, hid2 in text_similar_items:
        print(f"文字相似 HID1: {hid1}, HID2: {hid2}")
    
    # 開始進行圖片相似度比對
    image_folder = "C:\\Users\\user\\OneDrive\\桌面\\gold_house-複製"
    print("\n開始進行圖片相似度比對...")
    image_similar_items = find_image_similar_items(text_similar_items, image_folder, threshold=0.6)
    
    # 輸出圖片相似度比對結果
    print("圖片相似度比對結果:")
    for hid1, hid2 in image_similar_items:
        print(f"圖片相似 HID1: {hid1}, HID2: {hid2}")

if __name__ == "__main__":
    main()
