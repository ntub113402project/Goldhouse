import os
import json
import torch
from transformers import BertTokenizer, BertModel
from ckiptagger import WS

# 初始化模型
ws = WS("C:\\Users\\user\\OneDrive\\桌面\\data")
tokenizer = BertTokenizer.from_pretrained('bert-base-chinese')
bert_model = BertModel.from_pretrained('bert-base-chinese')

def get_bert_embedding(text):
    inputs = tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
    with torch.no_grad():
        outputs = bert_model(**inputs)
    return outputs.last_hidden_state[:, 0, :].cpu().tolist()

def extract_text_features(item):
    # 提取 address、pattern、size、type
    address_text = item['positionround'].get('address', '').strip()
    address_tokens = ws([address_text])
    VW_address = get_bert_embedding(' '.join(address_tokens[0]))

    pattern_text = item['houseinfo']['pattern']
    pattern_tokens = ws([pattern_text])
    VW_pattern = get_bert_embedding(' '.join(pattern_tokens[0]))

    VW_size = get_bert_embedding(item['houseinfo']['size'])
    VW_type = get_bert_embedding(item['houseinfo']['type'])

    # 提取 positionround 的 subway 和 bus
    subway_text = ' '.join(item['positionround'].get('subway', []))
    subway_tokens = ws([subway_text])
    VW_subway = get_bert_embedding(' '.join(subway_tokens[0]))

    bus_text = ' '.join(item['positionround'].get('bus', []))
    bus_tokens = ws([bus_text])
    VW_bus = get_bert_embedding(' '.join(bus_tokens[0]))

    # 提取 servicelist 中 "avaliable": true 的設備
    available_devices = [device_item['device'] for device_item in item['servicelist'] if device_item.get('avaliable', False)]
    VW_servicelist = get_bert_embedding(' '.join(available_devices))

    return {
        "hid": item.get('hid'),
        "VW_address": VW_address,
        "VW_pattern": VW_pattern,
        "VW_size": VW_size,
        "VW_type": VW_type,
        "VW_subway": VW_subway,
        "VW_bus": VW_bus,
        "VW_servicelist": VW_servicelist
    }

def extract_and_save_text_features(json_data, output_text_json):
    text_features = []

    for item in json_data:
        hid = item.get('hid')
        if not hid:
            print(f"跳過缺少 HID 的項目: {item}")
            continue

        text_feature = extract_text_features(item)
        text_features.append(text_feature)

        print(f"已經寫完 HID: {hid}")

    if text_features:
        print(f"提取數量: {len(text_features)}")
        print(f"正在寫入: {output_text_json}")

        os.makedirs(os.path.dirname(output_text_json), exist_ok=True)

        with open(output_text_json, 'w', encoding='utf-8') as f:
            json.dump(text_features, f, ensure_ascii=False, indent=4)
        print(f"文字特徵已成功存入 {output_text_json}")
    else:
        print("無法寫入JSON 文件。")

def main():
    json_file = "C:\\Users\\user\\OneDrive\\桌面\\detail.json"
    output_text_json = "C:\\Users\\user\\OneDrive\\桌面\\text_features.json"

    if os.path.exists(json_file):
        print(f"正在讀取: {json_file}")
        with open(json_file, 'r', encoding='utf-8') as f:
            json_data = json.load(f)
    else:
        print(f"文件 {json_file} 不存在，請檢查。")
        return

    if isinstance(json_data, list):
        extract_and_save_text_features(json_data, output_text_json)
    else:
        print("json_data 無效。")

if __name__ == "__main__":
    main()
