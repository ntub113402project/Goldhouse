import pandas as pd
import numpy as np
import json
import sys
from sklearn.feature_selection import SelectKBest, f_regression
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import TfidfVectorizer
import matplotlib.pyplot as plt

# 設定標準輸出編碼
sys.stdout.reconfigure(encoding='utf-8')

# 讀取 JSON 文件，使用正確的編碼
with open('detail.json', encoding='utf-8') as f:
    data = json.load(f)

# 轉換為 DataFrame
df = pd.json_normalize(data)

# 檢查 DataFrame 結構
print(df.info())
print(df.head().to_string())

# 處理類別型特徵
le = LabelEncoder()
df['Pattern'] = le.fit_transform(df['houseinfo.pattern'])
df['Type'] = le.fit_transform(df['houseinfo.type'])

# 添加額外的特徵
def extract_floor_info(layer):
    try:
        current, total = layer.split('/')
        current = int(current.replace('F', '').strip())
        total = int(total.replace('F', '').strip())
        return current, total
    except (ValueError, AttributeError):
        return np.nan, np.nan

df['Layer_Current'], df['Layer_Total'] = zip(*df['houseinfo.layer'].apply(extract_floor_info))

def parse_distance(distance_list):
    try:
        return min([int(item.split('距')[1].split('公尺')[0].strip()) for item in distance_list])
    except (ValueError, IndexError, AttributeError):
        return np.nan

df['Subway_Distance'] = df['positionround.subway'].apply(parse_distance)
df['Bus_Distance'] = df['positionround.bus'].apply(parse_distance)

# 刪除無效的行
df.dropna(subset=['Layer_Current', 'Layer_Total', 'Subway_Distance', 'Bus_Distance'], inplace=True)

# 準備特徵和目標變量
df['houseinfo.size'] = df['houseinfo.size'].apply(lambda x: float(x.replace('坪', '').strip()))
X = df[['Pattern', 'Type', 'houseinfo.size', 'Layer_Current', 'Layer_Total', 'Subway_Distance', 'Bus_Distance']]
y = df['houseinfo.price']

# 檢查特徵矩陣和目標變量
print(X.head().to_string())
print(y.head())

# 標準化特徵
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 選擇 k 個最重要的特徵
k = 5
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

print(importance_df.to_string())

# 可視化特徵重要性
plt.figure(figsize=(10, 6))
plt.barh(importance_df['Feature'], importance_df['Importance'])
plt.xlabel('Importance')
plt.title('Feature Importance')
plt.gca().invert_yaxis()
plt.show()

# 計算描述的相似度
description_vectorizer = TfidfVectorizer(stop_words='english')
description_matrix = description_vectorizer.fit_transform(df['remark.content'].apply(lambda x: ' '.join(x) if isinstance(x, list) else x))
similarity_matrix = cosine_similarity(description_matrix)

# 打印相似度矩陣
print("Similarity Matrix:\n", similarity_matrix)
