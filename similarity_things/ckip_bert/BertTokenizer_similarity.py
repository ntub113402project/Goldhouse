import re
from ckiptagger import WS
from transformers import BertModel, BertTokenizer
import torch
from torch.nn.functional import cosine_similarity
import jieba
import jieba.analyse

# Load models
tokenizer = BertTokenizer.from_pretrained("hfl/chinese-roberta-wwm-ext-large")
model = BertModel.from_pretrained("hfl/chinese-roberta-wwm-ext-large")
ws = WS("C:\\Users\\user\\OneDrive\\桌面\\data")

def preprocess_text(text):
    text = re.sub(r'[\s+\.\!\/_,$%^*(+\"\']+|[+——！，。？、~@#￥%……&*（）]+', '', text)
    text = re.sub(r'[\u3000]', '', text)
    return text

def get_word_vector(text, tokenizer, model, word_segmenter):
    # Segment the text using CKIPtagger
    segmented_text = ' '.join(word_segmenter([text])[0])
    # Tokenize and encode the segmented text
    inputs = tokenizer(segmented_text, add_special_tokens=True, return_tensors="pt", max_length=512, truncation=True, padding='max_length')
    outputs = model(**inputs)
    vector = outputs.last_hidden_state.mean(1).detach()
    return vector

def read_text_from_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as file:
        text = file.read()
    return preprocess_text(text)

def extract_keywords(text, topK=10):
    keywords = jieba.analyse.textrank(text, topK=topK, withWeight=False)
    return keywords

# File paths
file1 = "C:\\Users\\user\\OneDrive\\桌面\\ckip_bert\\sport_1.txt"
file2 = "C:\\Users\\user\\OneDrive\\桌面\\ckip_bert\\sport_2.txt"
file3 = "C:\\Users\\user\\OneDrive\\桌面\\ckip_bert\\Taiwan.txt"

text1 = read_text_from_file(file1)
text2 = read_text_from_file(file2)
text3 = read_text_from_file(file3)

preprocess_text1=preprocess_text(text1)
preprocess_text2=preprocess_text(text2)
preprocess_text3=preprocess_text(text3)

keywords1 = extract_keywords(preprocess_text1)
keywords2 = extract_keywords(preprocess_text2)
keywords3 = extract_keywords(preprocess_text3)

vector1 = get_word_vector(preprocess_text1, tokenizer, model, ws)
vector2 = get_word_vector(preprocess_text2, tokenizer, model, ws)
vector3 = get_word_vector(preprocess_text3, tokenizer, model, ws)



# Calculate cosine similarity for each pair
sim12 = cosine_similarity(vector1, vector2).item()
sim13 = cosine_similarity(vector1, vector3).item()
sim23 = cosine_similarity(vector2, vector3).item()

segmented_text1 = ws([text1])[0]
print(f"分词结果 for file1:{segmented_text1}")

print("相似度比較")
print(f"Similarity between file1 and file2: {sim12}")
print(f"Similarity between file1 and file3: {sim13}")
print(f"Similarity between file2 and file3: {sim23}")

print("關鍵字提取")
print(f"Keywords for file1: {keywords1}")
print(f"Keywords for file2: {keywords2}")
print(f"Keywords for file3: {keywords3}")
