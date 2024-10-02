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
ws = WS("C:\\Users\\ntubgoldhouse\\Desktop\\data")  # CKIP WS 模型路徑
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

# 計算餘弦相似度
def cosine_similarity(v1, v2):
    v1 = torch.tensor(v1, dtype=torch.float32)
    v2 = torch.tensor(v2, dtype=torch.float32)
    
    if v1.shape != v2.shape:
        raise ValueError(f"向量形狀不匹配: v1 {v1.shape}, v2 {v2.shape}")
    
    v1 = v1.unsqueeze(0)
    v2 = v2.unsqueeze(0)

    return F.cosine_similarity(v1, v2, dim=1).mean().item()

# 查詢目前資料庫中最大的 same 值
def get_max_same(connection):
    cursor = connection.cursor()
    cursor.execute("SELECT MAX(same) FROM gh_members.new_housedetail")
    max_same = cursor.fetchone()[0]
    cursor.close()
    return max_same if max_same else 0

# 更新 same 編號邏輯
def update_same_value(connection, new_hid, existing_same=None):
    cursor = connection.cursor()

    if existing_same is not None:
        # 如果找到相似的房屋，使用現有的 same 編號
        same_value = existing_same
    else:
        # 否則分配新的 same 編號
        same_value = get_max_same(connection) + 1

    cursor.execute("UPDATE gh_members.new_housedetail SET same = %s WHERE hid = %s", (same_value, new_hid))
    connection.commit()
    cursor.close()

# 處理文字數據，並存到資料庫
def process_text_data(hid, item):
    connection = connect_to_existing_database()  # 連接到 vmvp 資料庫
    cursor = connection.cursor()

    # 文字 WS 與 BERT
    address_text = item.get('address', '').strip()
    address_tokens = ws([address_text])
    VW_address = get_bert_embedding(' '.join(address_tokens[0]), tokenizer_zh, bert_model_zh)

    # 直接提取 pattern, size
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

    # 提取 device 中 "device = 1" 的設備
    available_devices = [device for device in item.get('device', []) if device == 1]
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

# 比較文字特徵
def compare_text_features(hid1, hid2):
    connection = connect_to_existing_database()  # 連接到 vmvp 資料庫
    cursor = connection.cursor(dictionary=True)
    
    # 提取兩個房屋的特徵向量
    cursor.execute("SELECT VW_address, VW_pattern, VW_size, VW_subway, VW_bus, VW_servicelist FROM house_data WHERE hid = %s OR hid = %s", (hid1, hid2))
    rows = cursor.fetchall()
    if len(rows) != 2:
        cursor.close()
        connection.close()
        return False

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
        return passes >= 2
    except ValueError as e:
        print(f"錯誤: {e}")
        return False
    finally:
        cursor.close()
        connection.close()

# 主函數
def main():
    # 連接到 gh_members 資料庫
    connection = connect_to_house_database()
    cursor = connection.cursor(dictionary=True)

    # 查詢資料庫中所有待處理的房屋文字資料
    cursor.execute("SELECT * FROM gh_members.new_housedetail WHERE same = 0")
    house_data = cursor.fetchall()

    # 處理文字資料並進行比較
    for i, item1 in enumerate(house_data):
        hid1 = item1['hid']
        process_text_data(hid1, item1)

        similar_found = False
        # 比較當前房屋與其他房屋是否相似
        for j, item2 in enumerate(house_data):
            if i != j and compare_text_features(hid1, item2['hid']):
                similar_found = True
                update_same_value(connection, hid1, item2['same'])
                break

        # 如果沒有找到相似的，分配新的 same 值
        if not similar_found:
            update_same_value(connection, hid1)

    cursor.close()
    connection.close()

    # 檢查碼
    print("準備就緒")

if __name__ == "__main__":
    main()
