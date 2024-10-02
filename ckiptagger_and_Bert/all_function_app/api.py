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
from flask import Flask, request, jsonify

# 初始化 CKIP、BERT、YOLO
ws = WS("C:\\Users\\ntubgoldhouse\\Desktop\\data")  # CKIP WS 模型路徑
tokenizer_zh = BertTokenizer.from_pretrained('bert-base-chinese')
bert_model_zh = BertModel.from_pretrained('bert-base-chinese')
yolo_model = YOLO("yolov8n.pt")

app = Flask(__name__)

# MySQL 資料庫連接（BERT 向量儲存）
def connect_to_existing_database():
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="ntubGH113402",
        database="vmvp"
    )
    return connection

# MySQL 資料庫連接（房屋資料及 same id 儲存）
def connect_to_house_database():
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="ntubGH113402",
        database="ghdetail"
    )
    return connection

# BERT 嵌入計算
def get_bert_embedding(text, tokenizer, model):
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
    return outputs.last_hidden_state[:, 0, :].cpu().tolist()

# 計算餘弦相似度
def cosine_similarity(v1, v2):
    v1 = torch.tensor(v1, dtype=torch.float32)
    v2 = torch.tensor(v2, dtype=torch.float32)
    
    if v1.shape != v2.shape:
        raise ValueError(f"向量形狀不匹配: v1 {v1.shape}, v2 {v2.shape}")
    
    v1 = v1.unsqueeze(0)
    v2 = v2.unsqueeze(0)

    return F.cosine_similarity(v1, v2, dim=1).mean().item()

# 處理文字數據，並存到資料庫
@app.route('/process_text', methods=['POST'])
def process_text():
    data = request.json
    hid = data['hid']
    item = data['item']

    connection = connect_to_existing_database()  # 連接到 vmvp 資料庫
    cursor = connection.cursor()

    # 直接提取地址、樣式、大小等
    address_text = item.get('address', '').strip()
    address_tokens = ws([address_text])
    VW_address = get_bert_embedding(' '.join(address_tokens[0]), tokenizer_zh, bert_model_zh)

    pattern_text = item.get('pattern', '')
    pattern_tokens = ws([pattern_text])
    VW_pattern = get_bert_embedding(' '.join(pattern_tokens[0]), tokenizer_zh, bert_model_zh)

    VW_size = get_bert_embedding(item.get('size', ''), tokenizer_zh, bert_model_zh)

    subway_text = ' '.join(item.get('subway', []))
    subway_tokens = ws([subway_text])
    VW_subway = get_bert_embedding(' '.join(subway_tokens[0]), tokenizer_zh, bert_model_zh)

    bus_text = ' '.join(item.get('bus', []))
    bus_tokens = ws([bus_text])
    VW_bus = get_bert_embedding(' '.join(bus_tokens[0]), tokenizer_zh, bert_model_zh)

    available_devices = item.get('device', [])
    if available_devices:
        VW_servicelist = get_bert_embedding(' '.join(available_devices), tokenizer_zh, bert_model_zh)
    else:
        VW_servicelist = None

    # 儲存到資料庫 vmvp.house_data
    cursor.execute("""
        INSERT INTO house_data (hid, VW_address, VW_pattern, VW_size, VW_subway, VW_bus, VW_servicelist)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON DUPLICATE KEY UPDATE VW_address = VALUES(VW_address), VW_pattern = VALUES(VW_pattern), 
        VW_size = VALUES(VW_size), VW_subway = VALUES(VW_subway), VW_bus = VALUES(VW_bus), VW_servicelist = VALUES(VW_servicelist)
    """, (hid, json.dumps(VW_address), json.dumps(VW_pattern), json.dumps(VW_size), json.dumps(VW_subway), json.dumps(VW_bus), json.dumps(VW_servicelist)))

    connection.commit()
    cursor.close()
    connection.close()

    return jsonify({"message": "Text processing and database storage completed"}), 200

# 處理圖片數據
@app.route('/process_image', methods=['POST'])
def process_image():
    data = request.json
    hid = data['hid']
    image_folder = "C://jpg"  # 圖片資料夾路徑

    # 使用 YOLO 模型對圖片進行處理
    images_path = os.path.join(image_folder, str(hid))
    if not os.path.exists(images_path):
        return jsonify({"error": "Image folder not found"}), 404

    image_files = [f for f in os.listdir(images_path) if f.endswith('.jpg')]
    detections = []

    for image_file in image_files:
        image_path = os.path.join(images_path, image_file)
        results = yolo_model(image_path)
        detections.append(results.pandas().xyxy[0].to_dict(orient="records"))

    return jsonify({"message": "Image processing completed", "detections": detections}), 200

# 比較兩個房屋的特徵
@app.route('/compare_text_features', methods=['POST'])
def compare_text_features():
    data = request.json
    hid1 = data.get('hid1')
    hid2 = data.get('hid2')

    if not hid1 or not hid2:
        return jsonify({"error": "Missing hid1 or hid2"}), 400

    connection = connect_to_existing_database()  # 連接到 vmvp 資料庫
    cursor = connection.cursor(dictionary=True)

    # 提取兩個房屋的特徵向量
    cursor.execute("""
        SELECT VW_address, VW_pattern, VW_size, VW_subway, VW_bus, VW_servicelist
        FROM house_data
        WHERE hid = %s OR hid = %s
    """, (hid1, hid2))
    
    rows = cursor.fetchall()
    if len(rows) != 2:
        cursor.close()
        connection.close()
        return jsonify({"error": "Failed to fetch feature vectors for comparison"}), 404

    item1, item2 = rows[0], rows[1]
    try:
        # 比較各個特徵向量
        address_sim = cosine_similarity(item1['VW_address'], item2['VW_address'])
        pattern_sim = cosine_similarity(item1['VW_pattern'], item2['VW_pattern'])
        size_sim = cosine_similarity(item1['VW_size'], item2['VW_size'])
        subway_sim = cosine_similarity(item1['VW_subway'], item2['VW_subway'])
        bus_sim = cosine_similarity(item1['VW_bus'], item2['VW_bus'])

        # 判斷是否相似
        subway_pass = subway_sim >= 0.8
        bus_pass = bus_sim >= 0.8
        servicelist_pass = False
        if item1['VW_servicelist'] and item2['VW_servicelist']:
            servicelist_sim = cosine_similarity(item1['VW_servicelist'], item2['VW_servicelist'])
            servicelist_pass = servicelist_sim >= 0.8

        # 如果 subway、bus、servicelist 中有兩個以上通過，則認為相似
        passes = [subway_pass, bus_pass, servicelist_pass].count(True)
        result = passes >= 2

        # 如果相似，更新 ghdetail.new_housedetail 的 same 字段
        if result:
            connection_house = connect_to_house_database()
            cursor_house = connection_house.cursor()
            cursor_house.execute("""
                UPDATE new_housedetail SET same = %s WHERE hid = %s
            """, (hid1, hid2))
            connection_house.commit()
            cursor_house.close()
            connection_house.close()

        return jsonify({"similar": result}), 200

    except ValueError as e:
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        connection.close()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5001, debug=True)
