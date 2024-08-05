import pandas as pd
import numpy as np
import random
from sklearn.feature_selection import SelectKBest, f_regression
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
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
    devices = ["冰箱", "洗衣機", "電視", "冷氣", "熱水器", "床", "衣櫃", "第四台", "網路", "天然瓦斯", "沙發", "桌椅", "陽台", "電梯", "車位"]
    
    for i in range(n):
        total_floors = random.randint(1, 15)
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
            "Description": random.choice(descriptions),
            "CurrentFloor": random.randint(1, total_floors),
            "TotalFloors": total_floors,
            "servicelist": {device: random.choice([True, False]) for device in devices}
        }
        houses.append(house)
    return houses

# 生成數據
data = generate_house_data(1500)

# 轉換為 DataFrame
df = pd.DataFrame(data)

# 檢查 DataFrame 結構
print(df.info())
print(df.head())

# 處理類別型特徵
le = LabelEncoder()
df['Location'] = le.fit_transform(df['Location'])
df['Style'] = le.fit_transform(df['Style'])

# 處理文本特徵（Description）
vectorizer = TfidfVectorizer(stop_words='english')
description_matrix = vectorizer.fit_transform(df['Description'])

# 計算每個描述的平均TF-IDF值
description_mean = description_matrix.mean(axis=1).A1
df['Description'] = description_mean

# 将 servicelist 转换为单一特徵（服务可用总数）
df['ServiceCount'] = df['servicelist'].apply(lambda x: sum(x.values()))

# 準備特徵和目標變量
X = df.drop(['id', 'Price', 'servicelist'], axis=1)  # 移除id和servicelist原始特徵，但保留ServiceCount特徵
y = df['Price']

# 檢查特徵矩陣和目標變量
print(X.head())
print(y.head())

# 標準化特徵
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 使用SelectKBest選擇k個最重要的特徵
k = 20  # 你可以根據需求調整k值
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
