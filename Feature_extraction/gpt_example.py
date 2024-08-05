import pandas as pd
import numpy as np
import json
import sys
from sklearn.feature_selection import SelectKBest, f_regression
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics.pairwise import cosine_similarity
import matplotlib.pyplot as plt

# 設定標準輸出編碼
sys.stdout.reconfigure(encoding='utf-8')

# 讀取 JSON 文件
with open('detail2.json', encoding='utf-8') as f:
    data = json.load(f)

# 轉換為 DataFrame
df = pd.json_normalize(data)

# 檢查 DataFrame 結構
print(df.info())
print(df.head().to_string())

# 處理類別型特徵
le_pattern = LabelEncoder()
df['houseinfo.pattern'] = le_pattern.fit_transform(df['houseinfo.pattern'])

le_type = LabelEncoder()
df['houseinfo.type'] = le_type.fit_transform(df['houseinfo.type'])

# 處理數值型特徵
df['houseinfo.size'] = df['houseinfo.size'].apply(lambda x: float(x.replace('坪', '').strip()))

def extract_floor_info(layer):
    try:
        # 常规情况
        if '/' in layer:
            current, total = layer.split('/')
            current = current.replace('F', '').strip()
            total = total.replace('F', '').strip()
            current = int(current) if current.isdigit() else np.nan
            total = int(total) if total.isdigit() else np.nan
            return current, total
        # 处理特殊情况
        elif '頂層加蓋' in layer:
            total = int(layer.split('/')[1].replace('F', '').strip())
            return total, total
        elif 'B' in layer:
            current, total = layer.split('/')
            current = -1 if 'B1' in current else np.nan
            total = int(total.replace('F', '').strip())
            return current, total
        elif '整棟' in layer:
            total = int(layer.split('/')[1].replace('F', '').strip())
            return total, total
        else:
            return np.nan, np.nan
    except (ValueError, AttributeError, IndexError):
        return np.nan, np.nan

df['Layer_Current'], df['Layer_Total'] = zip(*df['houseinfo.layer'].apply(extract_floor_info))

# 處理 servicelist 特徵
def servicelist_to_vector(servicelist, index):
    service_names = ["冰箱", "洗衣機", "電視", "冷氣", "熱水器", "床", "衣櫃", "第四台", "網路", "天然瓦斯", "沙發", "桌椅", "陽台", "電梯", "車位"]
    service_dict = {name: 0 for name in service_names}
    try:
        for service in servicelist:
            if service['avaliable']:
                service_dict[service['device']] = 1
    except Exception as e:
        print(f"Error processing servicelist for hid: {df.at[index, 'hid']}, error: {e}")
        return [np.nan] * len(service_names)
    return list(service_dict.values())

df['servicelist_vector'] = [servicelist_to_vector(servicelist, idx) for idx, servicelist in enumerate(df['servicelist'])]

# 檢查 vector 長度
vector_lengths = df['servicelist_vector'].apply(len)
if vector_lengths.nunique() > 1:
    print("Inconsistent vector lengths detected.")
    print(df[vector_lengths != vector_lengths.mode().iloc[0]].to_string())
else:
    print("All vector lengths are consistent.")

# 只保留長度一致的向量
consistent_length = vector_lengths.mode().iloc[0]
df = df[vector_lengths == consistent_length]
servicelist_vectors = np.array(df['servicelist_vector'].tolist())

# 刪除包含 NaN 的行
df = df.dropna(subset=['servicelist_vector'])
servicelist_vectors = np.array([vec for vec in servicelist_vectors if not np.isnan(vec).any()])

# 重新調整特徵矩陣，確保匹配
features = ['houseinfo.pattern', 'houseinfo.type', 'houseinfo.size', 'Layer_Current', 'Layer_Total', 'houseinfo.price']
df_features = df[features].reset_index(drop=True)
servicelist_vectors = pd.DataFrame(servicelist_vectors, columns=[f'service_{i}' for i in range(servicelist_vectors.shape[1])])
X_combined_df = pd.concat([df_features, servicelist_vectors], axis=1)

# 準備特徵矩陣
X = X_combined_df.drop(columns=['houseinfo.price'])
y = X_combined_df['houseinfo.price']

# 標準化特徵
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 檢查是否有 NaN 值
if np.isnan(X_scaled).any():
    nan_rows, nan_cols = np.where(np.isnan(X_scaled))
    for row, col in zip(nan_rows, nan_cols):
        print(f"NaN detected at row {row}, column {X.columns[col]} (hid: {df.iloc[row]['hid']})")
    raise ValueError("X_scaled contains NaN values")

# 選擇 k 個最重要的特徵
k = 30
selector = SelectKBest(score_func=f_regression, k=k)
X_selected = selector.fit_transform(X_scaled, y)

# 選取的重要特徵
selected_features_indices = selector.get_support(indices=True)
selected_features = [X.columns[i] for i in selected_features_indices]
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

# # 計算相似度矩陣
# similarity_matrix = cosine_similarity(X_scaled)

# # 顯示相似度矩陣
# print("Similarity Matrix:\n", similarity_matrix)

# # 計算與指定房屋的相似度
# def find_similar_houses(index, top_n=5):
#     similar_indices = similarity_matrix[index].argsort()[::-1][1:top_n+1]
#     similar_items = [(i, similarity_matrix[index][i]) for i in similar_indices]
#     return similar_items

# # 示例：找出與第0個房屋最相似的5個房屋
# similar_houses = find_similar_houses(0)
# print("Similar Houses to House 0:\n", similar_houses)
