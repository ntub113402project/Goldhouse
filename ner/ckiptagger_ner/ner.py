# pip install tensorflow==2.12.0rc0
# pip install keras==2.12.0rc0
# pip install ckiptagger

import json
import re
from ckiptagger import WS, POS, NER

ws = WS("C:\\Users\\user\\OneDrive\\桌面\\data")
pos = POS("C:\\Users\\user\\OneDrive\\桌面\\data")
ner = NER("C:\\Users\\user\\OneDrive\\桌面\\data")

input_file_path = "C:/Users/user/OneDrive/桌面/爬蟲/detail.json"
output_file_path = "C:/Users/user/OneDrive/桌面/nearby_ORG.json"

with open(input_file_path, "r", encoding="utf-8") as file:
    data = json.load(file)

data = [item for item in data if 'remark' in item and 'content' in item['remark'] and item['remark']['content']]


def clean_text(text):
    text = re.sub(r'[^\w\s]', '', text)
    text = re.sub(r'\s+', ' ', text)     
    return text

content_texts = [clean_text("\n".join(item['remark']['content'])) for item in data]

word_sentence_list = ws(content_texts)
pos_sentence_list = pos(word_sentence_list)
entity_sentence_lists = ner(word_sentence_list, pos_sentence_list)

results = []
for item, entity_sentence in zip(data, entity_sentence_lists):
    enhanced_entities = []
    content_combined = " ".join(item['remark']['content'])
    for entity in entity_sentence:
        if entity[2] == "ORG" and any(entity[3].endswith(suffix) for suffix in custom_keywords):
            enhanced_entities.append(entity[3])
    if enhanced_entities:
        results.append({"hid": item["hid"], "store": list(set(enhanced_entities))})

with open(output_file_path, "w", encoding="utf-8") as outfile:
    json.dump(results, outfile, ensure_ascii=False, indent=4)