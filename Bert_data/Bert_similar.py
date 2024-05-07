from transformers import BertModel, BertTokenizer
from torch.nn.functional import cosine_similarity
import torch

# BERT模型和分詞器
tokenizer = BertTokenizer.from_pretrained("hfl/chinese-roberta-wwm-ext-large")
model = BertModel.from_pretrained("hfl/chinese-roberta-wwm-ext-large")

def get_word_vector(text):
    # 透過預訓練的 Bert 分詞
    inputs = tokenizer(text,add_special_tokens=True, return_tensors="pt")
    # 轉化為詞向量
    outputs = model(**inputs)
    vector = outputs.last_hidden_state.mean(1).detach().numpy()[0]
    return vector.tolist()

#文本
vector1 = get_word_vector('半導體')
vector2 = get_word_vector('晶片')

#len(vector1)
#len(vector2)
#print(vector1)
#print(vector2)

# 一維張量->二維張量
#將列表形式的向量轉回PyTorch張量。
vector1_tensor = torch.tensor(vector1).unsqueeze(0)
vector2_tensor = torch.tensor(vector2).unsqueeze(0) 
similarity = cosine_similarity(vector1_tensor, vector2_tensor) 
#只取二維張量

print(f"相似度：{similarity.item()}")