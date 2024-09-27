import os
import json
import torch
import mysql.connector
from transformers import BertTokenizer, BertModel
from ckiptagger import WS
from ultralytics import YOLO
from PIL import Image
from collections import Counter
import numpy as np
import torch.nn.functional as F


# 初始化 CKIP、BERT、YOLO
ws = WS("C:\\Users\\user\\OneDrive\\桌面\\data")  # CKIP WS 模型路徑
tokenizer_zh = BertTokenizer.from_pretrained('bert-base-chinese')
bert_model_zh = BertModel.from_pretrained('bert-base-chinese')
yolo_model = YOLO("yolov8n.pt")

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
    return labels, image

# 提取主色
def get_dominant_color(image):
    image = image.resize((50, 50))
    pixels = np.array(image).reshape(-1, 3)
    counter = Counter(map(tuple, pixels))
    dominant_color = counter.most_common(1)[0][0]
    return dominant_color

# 處理文字數據，並存到資料庫
def process_text_data(hid, item):
    connection = connect_to_house_database()
    cursor = connection.cursor()

    # 文字 WS 與 BERT
    address_text = ' '.join(item['positionround'].get('address', []))
    address_tokens = ws([address_text])
    VW_address = get_bert_embedding(' '.join(address_tokens[0]), tokenizer_zh, bert_model_zh)

    pattern_text = item['houseinfo']['pattern']
    pattern_tokens = ws([pattern_text])
    VW_pattern = get_bert_embedding(' '.join(pattern_tokens[0]), tokenizer_zh, bert_model_zh)

    VW_size = get_bert_embedding(item['houseinfo']['size'], tokenizer_zh, bert_model_zh)
    VW_layer = get_bert_embedding(item['houseinfo']['layer'], tokenizer_zh, bert_model_zh)

    VW_servicelist_items = ' '.join([s.get('service', '') for s in item['servicelist']])
    VW_servicelist = get_bert_embedding(VW_servicelist_items, tokenizer_zh, bert_model_zh)

    # 儲存到資料庫
    cursor.execute("INSERT INTO text_features (hid, VW_address, VW_pattern, VW_size, VW_layer, VW_servicelist) VALUES (%s, %s, %s, %s, %s, %s)",
                   (hid, json.dumps(VW_address), json.dumps(VW_pattern), json.dumps(VW_size), json.dumps(VW_layer), json.dumps(VW_servicelist)))
    connection.commit()
    cursor.close()
    connection.close()

# 處理圖片數據，並存到資料庫
def process_image_data(hid, image_folder):
    connection = connect_to_existing_database()
    cursor = connection.cursor()

    image_folder_path = os.path.join(image_folder, hid)
    images = os.listdir(image_folder_path)
    
    for img in images:
        image_path = os.path.join(image_folder_path, img)
        labels, image = detect_objects(image_path)
        dominant_color = get_dominant_color(image)
        
        # YOLO + BERT 嵌入
        for label in labels:
            bert_features = get_bert_embedding(label, tokenizer_zh, bert_model_zh)
            cursor.execute("INSERT INTO image_features (hid, image_name, label, dominant_color, bert_features) VALUES (%s, %s, %s, %s, %s)",
                           (hid, img, label, str(dominant_color), json.dumps(bert_features)))
    connection.commit()
    cursor.close()
    connection.close()

# 比對並生成 same_id
def compare_and_generate_same_id(hid, item, data, text_threshold=0.8, image_threshold=0.5):
    # 比對文字與圖片
    for existing_item in data:
        if compare_text_features(item, existing_item, text_threshold):
            for img1 in item['VP_images']:
                for img2 in existing_item['VP_images']:
                    if compare_images(img1['objects'], img2['objects'], image_threshold):
                        return existing_item['same_id']
    return None

def main():
    # 圖片儲存路徑暫時待定
    image_folder = ""  # 圖片儲存路徑未定
    
    # 連接到 ghdetail 資料庫
    connection = connect_to_house_database()
    cursor = connection.cursor(dictionary=True)  # 使用 DictCursor 以便處理結果為字典格式
    
    # 查詢資料庫中所有待處理的房屋文字資料
    cursor.execute("SELECT * FROM house_details WHERE processed = 0")  # 假設資料庫中有個 processed 欄位標記是否處理
    house_data = cursor.fetchall()  # 取得所有未處理的房屋資料
    
    # 處理文字資料
    for item in house_data:
        hid = item['hid']

        # 處理並儲存房屋文字資料
        process_text_data(hid, item)
        
        # 更新已處理標記
        cursor.execute("UPDATE house_details SET processed = 1 WHERE hid = %s", (hid,))
        connection.commit()

    cursor.close()
    connection.close()

if __name__ == "__main__":
    main()
