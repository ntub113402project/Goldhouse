import pandas as pd
import numpy as np
import json
from sklearn.feature_selection import SelectKBest, f_regression
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import TfidfVectorizer
import matplotlib.pyplot as plt

# 讀取 JSON 文件
with open('testdata.json', encoding='utf-8') as f:
    data = json.load(f)

# 轉換為 DataFrame
df = pd.DataFrame(data)

# 檢查 DataFrame 結構
print(df.info())
print(df.head())

# 處理類別型特徵
le = LabelEncoder()
df['Location'] = le.fit_transform(df['Location'])
df['Style'] = le.fit_transform(df['Style'])

# 準備特徵和目標變量
X = df.drop(['Price', 'Description'], axis=1)
y = df['Price']

# 檢查特徵矩陣和目標變量
print(X.head())
print(y.head())

# 標準化特徵
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 選擇 k 個最重要的特徵
k = 10
selector = SelectKBest(score_func=f_regression, k=k)
X_selected = selector.fit_transform(X_scaled, y)

# 選取的重要特徵
selected_features = X.columns[selector.get_support(indices=True)]
print(f"Selected features: {selected_features}")

# 訓練隨機森林模型
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_selected, y)

# 獲取特徵重要性
feature_importances = model.feature_importances_

# 創建特徵重要性 DataFrame
importance_df = pd.DataFrame({
    'Feature': selected_features,
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
description_vectorizer = TfidfVectorizer(stop_words='english')
description_matrix = description_vectorizer.fit_transform(df['Description'])
similarity_matrix = cosine_similarity(description_matrix)

# 打印相似度矩陣
print("Similarity Matrix:\n", similarity_matrix)
