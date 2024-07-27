import pandas as pd
import numpy as np
import random
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
import matplotlib.pyplot as plt

# 模擬數據集生成
def generate_house_data(n):
    houses = []
    locations = ["Taipei", "Kaohsiung", "Tainan"]
    styles = ["Modern", "Contemporary", "Victorian"]
    descriptions = [
        "Spacious modern house in city center.",
        "Modern house with spacious rooms.",
        "House with pool and garden.",
        "Spacious house with garden.",
        "House with modern amenities.",
        "Elegant house with modern features."
    ]
    
    for i in range(n):
        house = {
            "id": i + 1,
            "Location": random.choice(locations),
            "Area": random.randint(1000, 2000),
            "Price": random.randint(20000, 50000),
            "Bedrooms": random.randint(1, 5),
            "Bathrooms": random.randint(1, 3),
            "YearBuilt": random.randint(1990, 2020),
            "Garage": random.randint(0, 2),
            "Pool": random.randint(0, 1),
            "Garden": random.randint(0, 1),
            "Floors": random.randint(1, 3),
            "Style": random.choice(styles),
            "Basement": random.randint(0, 1),
            "Balcony": random.randint(0, 1),
            "Fireplace": random.randint(0, 1),
            "Description": random.choice(descriptions)
        }
        houses.append(house)
    return houses

# 生成100筆數據
houses = generate_house_data(100)

# 將數據轉換為 DataFrame
df = pd.DataFrame(houses)

# 假設隨機生成相似房屋組合
def generate_similar_groups(n, max_group_size):
    ids = list(range(1, n+1))
    random.shuffle(ids)
    groups = []
    while len(ids) > 0:
        group_size = random.randint(2, max_group_size)
        group = ids[:group_size]
        ids = ids[group_size:]
        if len(group) > 1:
            groups.append(group)
    return groups

# 生成相似房屋組合
similar_groups = generate_similar_groups(100, 5)

# 將相似房屋組合映射到每筆數據
df['Label'] = [None] * len(df)
for group in similar_groups:
    for id in group:
        df.at[id - 1, 'Label'] = group

# 確保所有數據都有相似組合標籤
df['Label'] = df['Label'].apply(lambda x: x if x is not None else [random.randint(1, 100)])

# 對類別特徵進行編碼
le = LabelEncoder()
df['Location'] = le.fit_transform(df['Location'])
df['Style'] = le.fit_transform(df['Style'])

# 處理文本特徵（Description）
vectorizer = TfidfVectorizer(stop_words='english')
description_matrix = vectorizer.fit_transform(df['Description'])

# 將文本特徵轉換為 DataFrame 並合併
description_df = pd.DataFrame(description_matrix.toarray(), columns=vectorizer.get_feature_names_out())
df = df.join(description_df).drop(columns=['Description'])

# 準備特徵和目標變量
X = df.drop(['Price', 'Label', 'id'], axis=1)
y = df['Label'].apply(lambda x: x[0])

# 標準化特徵
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 訓練隨機森林模型
model = RandomForestClassifier(n_estimators=100, random_state=42)
model.fit(X_scaled, y)

# 獲取特徵重要性
feature_importances = model.feature_importances_
importance_df = pd.DataFrame({
    'Feature': X.columns,
    'Importance': feature_importances
}).sort_values(by='Importance', ascending=False)

print(importance_df)

# 可視化特徵重要性
plt.figure(figsize=(14, 10))
plt.barh(importance_df['Feature'], importance_df['Importance'], color='tab:blue', alpha=0.6)
plt.xlabel('Importance', fontsize=14)
plt.ylabel('Feature', fontsize=14)
plt.title('Feature Importance', fontsize=16)
plt.gca().invert_yaxis()
plt.show()
