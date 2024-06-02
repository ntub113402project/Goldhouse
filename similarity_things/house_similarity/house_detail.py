import json
import torch
import torch.nn.functional as F
from ckiptagger import WS #, POS, NER
from transformers import BertTokenizer, BertModel
import re

ws = WS("D:\\AI_data\\data")
"""
pos = POS("D:\\AI_data\\data")
ner = NER("D:\\AI_data\\data")
"""
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
    for item in items:
        address_text = ' '.join([str(a).strip() for a in item['positionround'].get('address', [])])
        address_tokens = ws([address_text])
        item['address_emb'] = get_bert_embedding(' '.join(address_tokens[0]))
    return items

def cosine_similarity(tensor1, tensor2):
    return F.cosine_similarity(tensor1.unsqueeze(0), tensor2.unsqueeze(0)).item()

def device_similarity(devices1, devices2):
    common_devices = set(d1['device'] for d1 in devices1).intersection(set(d2['device'] for d2 in devices2))
    matched = sum(1 for d1 in devices1 for d2 in devices2 if d1['device'] == d2['device'] and d1['avaliable'] == d2['avaliable'])
    return matched / min(len(devices1), len(devices2)) >= 0.7

#描述比較
"""
def clean_remark_content(content):
    content = ' '.join(content) if isinstance(content, list) else content
    words = ws([content])
    pos_tags = pos(words)
    entities = ner(words, pos_tags)
    
    clean_content = []
    for word, pos_tag, entity in zip(words[0], pos_tags[0], entities[0]):
        if pos_tag in {'Nc'} or entity[1] in {'LOC'}: #地點名詞、地理位置
            clean_content.append(word)
    
    cleaned_text = ' '.join(clean_content)
    cleaned_text = re.sub(r'\b(?:\d{1,3}[-.\s]?){3,4}\d{1,4}\b', '', cleaned_text) 
    cleaned_text = re.sub(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', '', cleaned_text)  
    cleaned_text = re.sub(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+', '', cleaned_text)  
    cleaned_text = re.sub(r'[^\w\s]', '', cleaned_text)  
    return cleaned_text
    
#描述比較的閥值設定
def is_description_similar(desc1, desc2):
    emb1 = get_bert_embedding(desc1)
    emb2 = get_bert_embedding(desc2)
    similarity = cosine_similarity(emb1, emb2)
    return similarity >= 0.6
"""

def get_tokenized_text(text):
    tokens = ws([text])
    return ' '.join(tokens[0])

def compare_patterns(pattern1, pattern2):
    tokenized_pattern1 = get_tokenized_text(pattern1)
    tokenized_pattern2 = get_tokenized_text(pattern2)
    emb1 = get_bert_embedding(tokenized_pattern1)
    emb2 = get_bert_embedding(tokenized_pattern2)
    similarity = cosine_similarity(emb1, emb2)
    return similarity > 0.9

def compare_layers(layer1, layer2):
    layers1 = layer1.split('/')
    layers2 = layer2.split('/')
    similarities = []
    for l1 in layers1:
        for l2 in layers2:
            tokenized_layer1 = get_tokenized_text(l1)
            tokenized_layer2 = get_tokenized_text(l2)
            emb1 = get_bert_embedding(tokenized_layer1)
            emb2 = get_bert_embedding(tokenized_layer2)
            similarity = cosine_similarity(emb1, emb2)
            similarities.append(similarity)
    return max(similarities) > 0.9

def find_similar_items(data):
    similar_items = []
    n = len(data)
    for i in range(n):
        for j in range(i + 1, n):
            address_similarity = cosine_similarity(data[i]['address_emb'], data[j]['address_emb']) > 0.9
            if address_similarity:
                pattern_match = compare_patterns(data[i]['houseinfo']['pattern'], data[j]['houseinfo']['pattern'])
                size_match = compare_patterns(data[i]['houseinfo']['size'], data[j]['houseinfo']['size'])
                layer_match = compare_layers(data[i]['houseinfo']['layer'], data[j]['houseinfo']['layer'])
                device_match = device_similarity(data[i]['servicelist'], data[j]['servicelist'])
                #description_match = is_description_similar(clean_remark_content(data[i]['remark']['content']), clean_remark_content(data[j]['remark']['content']))
                if pattern_match and size_match and layer_match and device_match: # and description_match:
                    similar_items.append((data[i]['hid'], data[j]['hid']))
    return similar_items

def main():
    json_data = load_json("D:\\AI_data\\detail.json")
    complete_data = preprocess_data(json_data)
    similar_items = find_similar_items(complete_data)
    print("Similar Items:")
    for hid1, hid2 in similar_items[:3]:  
        print(f"HID1: {hid1}, HID2: {hid2}")

if __name__ == "__main__":
    main()
