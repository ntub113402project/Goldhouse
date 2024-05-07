import tensorflow as tf
import logging

# Suppress TensorFlow warnings
tf.compat.v1.logging.set_verbosity(tf.compat.v1.logging.ERROR)
logging.getLogger('tensorflow').setLevel(logging.ERROR)

import json
import torch
from ckiptagger import WS
from transformers import BertTokenizer, BertModel

ws = WS("C:\\Users\\user\\OneDrive\\桌面\\AI_data\\data")
tokenizer = BertTokenizer.from_pretrained('bert-base-chinese')
model = BertModel.from_pretrained('bert-base-chinese')

def get_bert_embedding(text):
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
    with torch.no_grad():
        outputs = model(**inputs)
    return outputs.last_hidden_state[:, 0, :].squeeze()

def load_json(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        return json.load(file)

def preprocess_data(items):
    missing_data = []
    complete_data = []
    for item in items:
        subway = item.get('positionround', {}).get('subway', [])
        address = item.get('positionround', {}).get('address', [])
        bus = item.get('positionround', {}).get('bus', [])
        if not subway or not address or not bus:
            missing_data.append(item)
        else:
            subway_text = ' '.join([str(s).strip() for s in subway])
            address_text = ' '.join([str(a).strip() for a in address])
            bus_text = ' '.join([str(b).strip() for b in bus])
            subway_tokens = ws([subway_text])
            address_tokens = ws([address_text])
            bus_tokens = ws([bus_text])
            item['subway_emb'] = get_bert_embedding(' '.join(subway_tokens[0]))
            item['address_emb'] = get_bert_embedding(' '.join(address_tokens[0]))
            item['bus_emb'] = get_bert_embedding(' '.join(bus_tokens[0]))
            complete_data.append(item)
    return complete_data, missing_data

def find_similar_items(data):
    similar_items = []
    n = len(data)
    for i in range(n):
        for j in range(i + 1, n):
            if 'positionround' in data[i] and 'positionround' in data[j]:
                subway_match = (data[i]['positionround'].get('subway', []) == data[j]['positionround'].get('subway', []))
                address_match = (data[i]['positionround'].get('address', []) == data[j]['positionround'].get('address', []))
                bus_match = (data[i]['positionround'].get('bus', []) == data[j]['positionround'].get('bus', []))
                if subway_match or address_match or bus_match:
                    similar_items.append((data[i]['hid'], data[j]['hid']))
    return similar_items


def main():
    json_data = load_json("C:\\Users\\user\\OneDrive\\桌面\\detail.json")
    complete_data, missing_data = preprocess_data(json_data)
    
    print("Missing complete information (address, subway, or bus):", len(missing_data))
    similar_items = find_similar_items(complete_data)
    print("Similar Items:")
    if similar_items:
        for hid1, hid2 in similar_items[:5]:  
            print(f"HID1: {hid1}, HID2: {hid2}")
    else:
        print("No similar items found.")

if __name__ == "__main__":
    main()
