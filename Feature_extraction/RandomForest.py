import pandas as pd
import numpy as np
import json
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics.pairwise import cosine_similarity
import matplotlib.pyplot as plt

# 讀取 JSON 文件
with open('data.json') as f:
    data = json.load(f)

# 轉換為 DataFrame
df = pd.DataFrame(data)

# 處理文本特徵（Description）
vectorizer = TfidfVectorizer(stop_words='english')
description_matrix = vectorizer.fit_transform(df['Description'])

# 將文本特徵轉換為 DataFrame 並合併
description_df = pd.DataFrame(description_matrix.toarray(), columns=vectorizer.get_feature_names_out())
df = df.join(description_df).drop(columns=['Description'])

# 添加假設的 Label 標籤（1 表示重複，0 表示不重複）
# 這裡僅作為示例，實際應根據你的標籤數據進行設置
df['Label'] = [1, 1, 0, 0, 0, 1, 1, 0, 1, 0]

# 準備特徵和目標變量
X = df.drop(['Price', 'Label'], axis=1)  # 假設 'Label' 是標籤
y = df['Label']

# 對類別特徵進行編碼
le = LabelEncoder()
X['Location'] = le.fit_transform(X['Location'])
X['Style'] = le.fit_transform(X['Style'])

# 訓練隨機森林模型
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X, y)

# 獲取特徵重要性
feature_importances = model.feature_importances_
feature_names = X.columns

# 創建特徵重要性 DataFrame
importance_df = pd.DataFrame({
    'Feature': feature_names,
    'Importance': feature_importances
}).sort_values(by='Importance', ascending=False)

print(importance_df)

# 可視化特徵重要性
plt.figure(figsize=(10, 6))
plt.barh(importance_df['Feature'], importance_df['Importance'])
plt.xlabel('Importance')
plt.title('Feature Importance')
plt.gca().invert_yaxis()
plt.show()

# 計算描述的相似度
similarity_matrix = cosine_similarity(description_matrix)

# 打印相似度矩陣
print("Similarity Matrix:\n", similarity_matrix)
