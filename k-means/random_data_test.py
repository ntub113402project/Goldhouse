import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from mpl_toolkits.mplot3d import Axes3D

# 1. 創建包含房屋數據的 JSON 文件（包括文字特徵“房屋類型”）
data = [
    {'id': i+1, 'Total Square Footage': np.random.randint(1000, 4000), 'Number of Rooms': np.random.randint(2, 10),
     'Number of Bathrooms': np.random.randint(1, 5), 'Number of Floors': np.random.randint(1, 4),
     'Year Built': np.random.randint(1950, 2022), 'Price': np.random.randint(200000, 1000000),
     'House Type': np.random.choice(['電梯大樓', '公寓', '透天厝'])} for i in range(2000)
]

# 創建 DataFrame
df = pd.DataFrame(data)

# 對文字特徵進行 One-Hot Encoding
one_hot_encoder = OneHotEncoder()
encoded_features = one_hot_encoder.fit_transform(df[['House Type']]).toarray()
encoded_feature_names = one_hot_encoder.get_feature_names_out(['House Type'])

# 創建包含編碼特徵的 DataFrame
encoded_df = pd.DataFrame(encoded_features, columns=encoded_feature_names)

# 將原始數據和編碼特徵合併
df = df.drop(columns=['House Type'])
df = pd.concat([df, encoded_df], axis=1)

# 標準化數據
scaler = StandardScaler()
scaled_data = scaler.fit_transform(df.drop(columns=['id']))

# 定義 k-means 模型，設置聚類數目為 3
kmeans = KMeans(n_clusters=5, random_state=42)

# 訓練模型
kmeans.fit(scaled_data)

# 獲取聚類結果
labels = kmeans.labels_
centers = kmeans.cluster_centers_

# 添加聚類標籤到原始數據
df['Cluster'] = labels

# 視覺化結果
fig = plt.figure(figsize=(14, 7))

# 列出各群組所包含的樣本 id
for cluster in range(kmeans.n_clusters):
    cluster_ids = df[df['Cluster'] == cluster]['id'].tolist()
    print(f'Cluster {cluster} contains samples with ids: {cluster_ids}')

# 輸出聚類結果
print(df)

# 三維視覺化：選擇三個主要特徵進行可視化
ax = fig.add_subplot(121, projection='3d')
scatter = ax.scatter(scaled_data[:, 0], scaled_data[:, 1], scaled_data[:, 2], c=labels, cmap='viridis', marker='o')
ax.set_title('3D K-means Clustering of Houses')
ax.set_xlabel('Total Square Footage (scaled)')
ax.set_ylabel('Number of Rooms (scaled)')
ax.set_zlabel('Number of Bathrooms (scaled)')

# 標記每個群組的編號
for i, center in enumerate(centers):
    ax.text(center[0], center[1], center[2], f'Cluster {i}', color='red', fontsize=12, weight='bold')

# 二維視覺化：選擇兩個特徵進行可視化
ax2 = fig.add_subplot(122)
scatter = ax2.scatter(scaled_data[:, 0], scaled_data[:, 1], c=labels, cmap='viridis', marker='o')
ax2.set_title('2D K-means Clustering of Houses')
ax2.set_xlabel('Total Square Footage (scaled)')
ax2.set_ylabel('Number of Rooms (scaled)')

# 標記每個群組的編號
for i, center in enumerate(centers):
    ax2.text(center[0], center[1], f'Cluster {i}', color='red', fontsize=12, weight='bold')

# 添加圖例
legend1 = ax2.legend(*scatter.legend_elements(), title="Clusters")
ax2.add_artist(legend1)

plt.show()