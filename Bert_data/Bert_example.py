from transformers import BertTokenizer, BertModel
#from neo4j import GraphDatabase
import numpy as np

# 初始化BERT模型和分詞器
tokenizer = BertTokenizer.from_pretrained("hfl/chinese-roberta-wwm-ext-large")
model = BertModel.from_pretrained("hfl/chinese-roberta-wwm-ext-large")

def get_word_vector(text):
    # 透過預訓練的 Bert 分詞
    inputs = tokenizer(text, return_tensors="pt")
    # 轉化為詞向量
    outputs = model(**inputs)
    vector = outputs.last_hidden_state.mean(1).detach().numpy()[0]
    return vector.tolist()

vector1 = get_word_vector('半導體')
vector2 = get_word_vector('晶片')
len(vector1)

print(vector1)