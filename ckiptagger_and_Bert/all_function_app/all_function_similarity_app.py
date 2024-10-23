import os
import json
import torch
import mysql.connector
from transformers import BertTokenizer, BertModel
from ckiptagger import WS, NER
from ultralytics import YOLO
from PIL import Image
from collections import Counter
import numpy as np
import torch.nn.functional as F
from concurrent.futures import ThreadPoolExecutor

# 初始化 CKIP、BERT、YOLO
ws = WS("C:\\Users\\user\\OneDrive\\桌面\\data")  # CKIP WS 模型路徑
ner = NER("C:\\Users\\user\\OneDrive\\桌面\\data")
tokenizer_zh = BertTokenizer.from_pretrained('bert-base-chinese')
bert_model_zh = BertModel.from_pretrained('bert-base-chinese')
yolo_model = YOLO("yolov8n.pt")

# 自定義後綴與排除條件
custom_suffixes = [
    "公園", "學校", "醫院", "機構", "市", "店", "超市", "站", "中心", "街",
    "市場", "公司", "高中", "小學", "幼兒園", "大學", "學院", "診所", "館",
    "局", "廣場", "院", "場所", "廟", "堂"
]

exclusions = ["不動產", "加盟店", "直營店", "元大花廣圓頂世紀館", "住都中心", "台北聯勝租賃部"]

# MySQL 資料庫連接（BERT 向量儲存）
def connect_to_existing_database():
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="ntubGH113402",
        database="vmvp"  # 使用現有的資料庫
    )
    return connection

# MySQL 資料庫連接（房屋資料及 same id 儲存）
def connect_to_house_database():
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="ntubGH113402",
        database="ghdetail"  # 使用現有的資料庫
    )
    return connection

# BERT 嵌入計算
def get_bert_embedding(text, tokenizer, model):
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
    return outputs.last_hidden_state[:, 0, :].cpu().tolist()  # 取得 [CLS] 向量

# YOLO 偵測物件
def detect_objects(image_path):
    results = yolo_model(image_path)
    image = Image.open(image_path)
    labels = [yolo_model.names[int(cls)] for cls in results[0].boxes.cls.tolist()]  # YOLO 偵測到的物件名稱
    positions = results[0].boxes.xyxy.cpu().numpy().tolist()  # 提取 YOLO 偵測到的位置
    return labels, positions, image

# 提取主色
def get_dominant_color(image):
    image = image.resize((50, 50))
    pixels = np.array(image).reshape(-1, 3)
    counter = Counter(map(tuple, pixels))
    dominant_color = counter.most_common(1)[0][0]
    return dominant_color

# 計算餘幣相似度
def cosine_similarity(v1, v2):
    v1 = torch.tensor(v1, dtype=torch.float32)
    v2 = torch.tensor(v2, dtype=torch.float32)
    
    if v1.shape != v2.shape:
        raise ValueError(f"向量形狀不匹配: v1 {v1.shape}, v2 {v2.shape}")
    
    v1 = v1.unsqueeze(0)
    v2 = v2.unsqueeze(0)

    return F.cosine_similarity(v1, v2, dim=1).mean().item()

# 處理文字數據，並存到資料庫
def process_text_data(hid, item):
    connection = connect_to_house_database()
    cursor = connection.cursor()

    # 文字 WS 與 BERT
    address_text = item['positionround'].get('address', '').strip()
    address_tokens = ws([address_text])
    VW_address = get_bert_embedding(' '.join(address_tokens[0]), tokenizer_zh, bert_model_zh)

    pattern_text = item['houseinfo']['pattern']
    pattern_tokens = ws([pattern_text])
    VW_pattern = get_bert_embedding(' '.join(pattern_tokens[0]), tokenizer_zh, bert_model_zh)

    VW_size = get_bert_embedding(item['houseinfo']['size'], tokenizer_zh, bert_model_zh)
    VW_type = get_bert_embedding(item['houseinfo']['type'], tokenizer_zh, bert_model_zh)

    subway_text = ' '.join(item['positionround'].get('subway', []))
    subway_tokens = ws([subway_text])
    VW_subway = get_bert_embedding(' '.join(subway_tokens[0]), tokenizer_zh, bert_model_zh)

    bus_text = ' '.join(item['positionround'].get('bus', []))
    bus_tokens = ws([bus_text])
    VW_bus = get_bert_embedding(' '.join(bus_tokens[0]), tokenizer_zh, bert_model_zh)

    # 提取 servicelist 中 "avaliable": true 的設備
    available_devices = [device_item['device'] for device_item in item['servicelist'] if device_item.get('avaliable', False)]
    VW_servicelist = get_bert_embedding(' '.join(available_devices), tokenizer_zh, bert_model_zh)

    # 使用 NER 提取位置實體
    content = item['remark'].get('content', '')
    sentences = ws([content])
    ner_results = ner(sentences)
    location_entities = []
    for sentence, ners in zip(sentences, ner_results):
        for name, (ner_tag, _) in zip(sentence, ners):
            if ner_tag == 'LOC' and not any(excl in name for excl in exclusions):
                location_entities.append(name)
    # 預處理 NER 結果
    processed_locations = preprocess_names(location_entities)
    VW_NER = get_bert_embedding(' '.join(processed_locations), tokenizer_zh, bert_model_zh)

    # 儲存到資料庫
    cursor.execute("INSERT INTO text_features (hid, VW_address, VW_pattern, VW_size, VW_type, VW_subway, VW_bus, VW_servicelist, location_entities, VW_NER) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                   (hid, json.dumps(VW_address), json.dumps(VW_pattern), json.dumps(VW_size), json.dumps(VW_type), json.dumps(VW_subway), json.dumps(VW_bus), json.dumps(VW_servicelist), json.dumps(processed_locations), json.dumps(VW_NER)))
    connection.commit()
    cursor.close()
    connection.close()

# 比較文字特徵
def compare_text_features(item1, item2):
    try:
        # 比較 address
        address_sim = cosine_similarity(item1['VW_address'], item2['VW_address'])
        if address_sim < 1:
            return False

        # 比較 pattern
        pattern_sim = cosine_similarity(item1['VW_pattern'], item2['VW_pattern'])
        if pattern_sim <= 0.9:
            return False

        # 比較 size
        size_sim = cosine_similarity(item1['VW_size'], item2['VW_size'])
        if size_sim < 1:
            return False

        # 比較 type
        type_sim = cosine_similarity(item1['VW_type'], item2['VW_type'])
        if type_sim < 0.8:
            return False

        # 比較 positionround 的 subway
        subway_sim = cosine_similarity(item1['VW_subway'], item2['VW_subway'])
        bus_sim = cosine_similarity(item1['VW_bus'], item2['VW_bus'])
        servicelist_sim = None

        # 比較 positionround 的 bus
        if subway_sim >= 0.8:
            subway_pass = True
        else:
            subway_pass = False

        if bus_sim >= 0.8:
            bus_pass = True
        else:
            bus_pass = False

        # 比較 servicelist 可用設備
        if item1.get('VW_servicelist') and item2.get('VW_servicelist'):
            servicelist_sim = cosine_similarity(item1['VW_servicelist'], item2['VW_servicelist'])
            servicelist_pass = servicelist_sim >= 0.8
        else:
            servicelist_pass = False

        # 如果 subway、bus、servicelist 中有兩個以上通過，則認為相似
        passes = [subway_pass, bus_pass, servicelist_pass].count(True)
        if passes < 2:
            return False

        return True
    except ValueError as e:
        print(f"錯誤: {e}")
        return False

# 處理圖片數據，並存到資料庫
def process_image_data(hid, image_folder):
    connection = connect_to_existing_database()
    cursor = connection.cursor()

    image_folder_path = os.path.join(image_folder, hid)
    images = os.listdir(image_folder_path)
    
    for img in images:
        image_path = os.path.join(image_folder_path, img)
        labels, positions, image = detect_objects(image_path)
        dominant_color = get_dominant_color(image)
        
        # YOLO + BERT 嵌入
        for label, position in zip(labels, positions):
            bert_features = get_bert_embedding(label, tokenizer_zh, bert_model_zh)
            cursor.execute("INSERT INTO image_features (hid, image_name, label, dominant_color, bert_features, position) VALUES (%s, %s, %s, %s, %s, %s)",
                           (hid, img, label, str(dominant_color), json.dumps(bert_features), json.dumps(position)))
    connection.commit()
    cursor.close()
    connection.close()

# 比較圖片位置
def compare_image_positions(pos1, pos2):
    # 計算位置相似度，當相似度大於 0.4 時認為是相同位置
    pos1 = np.array(pos1)
    pos2 = np.array(pos2)
    iou = calculate_iou(pos1, pos2)
    return iou > 0.4

# 計算 IOU（Intersection over Union）
def calculate_iou(box1, box2):
    xA = max(box1[0], box2[0])
    yA = max(box1[1], box2[1])
    xB = min(box1[2], box2[2])
    yB = min(box1[3], box2[3])

    interArea = max(0, xB - xA) * max(0, yB - yA)
    box1Area = (box1[2] - box1[0]) * (box1[3] - box1[1])
    box2Area = (box2[2] - box2[0]) * (box2[3] - box2[1])

    iou = interArea / float(box1Area + box2Area - interArea)
    return iou

def main():
    # 圖片儲存路徑
    image_folder = "C:\\jpg"
    
    # 連接到 ghdetail 資料庫
    connection = connect_to_house_database()
    cursor = connection.cursor(dictionary=True)  # 使用 DictCursor 以便處理結果為字典格式
    
    # 查詢資料庫中所有待處理的房屋文字資料
    cursor.execute("SELECT * FROM house_details WHERE processed = 0")  # 假設資料庫中有個 processed 欄位標誌是否處理
    house_data = cursor.fetchall()  # 取得所有未處理的房屋資料
    
    # 處理文字資料
    for item in house_data:
        hid = item['hid']

        # 處理並儲存房屋文字資料
        process_text_data(hid, item)
        
        # 更新已處理標誌
        cursor.execute("UPDATE house_details SET processed = 1 WHERE hid = %s", (hid,))
        connection.commit()

        # 處理圖片資料
        process_image_data(hid, image_folder)

    cursor.close()
    connection.close()

if __name__ == "__main__":
    main()
