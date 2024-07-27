import numpy as np
import os
import json
import joblib
import matplotlib.pyplot as plt
from sklearn.cluster import MiniBatchKMeans
from mpl_toolkits.mplot3d import Axes3D
import sys
import time

# 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

# 定义模型文件和数据文件路径
model_file = 'kmeans_model.pkl'
data_file = 'data.json'

# 生成新数据
new_data = np.random.rand(100, 3)  # 新的三维数据

# 测试数据加载和增量训练的时间
start_time = time.time()

# 如果数据文件存在，则加载数据，否则初始化数据文件
if os.path.exists(data_file):
    with open(data_file, 'r') as f:
        all_data = json.load(f)
    print("数据文件存在，载入数据...")
else:
    all_data = []
    print("数据文件不存在，初始化数据...")

# 添加新数据到所有数据中
all_data.extend(new_data.tolist())

# 将所有数据写回数据文件
with open(data_file, 'w') as f:
    json.dump(all_data, f)

# 将所有数据转换为 numpy 数组
combined_data = np.array(all_data)

if os.path.exists(model_file):
    # 如果模型存在，则加载模型，并进行增量训练
    kmeans_loaded = joblib.load(model_file)
    print("模型存在，进行增量训练...")
    
    # 使用所有数据进行增量训练
    kmeans_loaded.partial_fit(combined_data)
else:
    # 如果模型不存在，则使用所有数据进行训练并保存模型
    print("模型不存在，随机生成数据进行训练...")
    
    # 训练 MiniBatchKMeans 模型并保存
    kmeans_loaded = MiniBatchKMeans(n_clusters=5, random_state=42, batch_size=10)
    kmeans_loaded.fit(combined_data)
    
    # 保存模型
    joblib.dump(kmeans_loaded, model_file)

end_time = time.time()
elapsed_time = end_time - start_time
print(f"数据加载和增量训练花费了 {elapsed_time:.6f} 秒")
print(f"all data size : {len(all_data)}")

# 获取聚类结果
combined_labels = kmeans_loaded.predict(combined_data)
combined_centers = kmeans_loaded.cluster_centers_

# 可视化聚类结果
fig = plt.figure(figsize=(12, 10))  # 调整图形大小，使其更加适合显示 3D 图形

# 3D图
ax = fig.add_subplot(111, projection='3d')
scatter = ax.scatter(combined_data[:, 0], combined_data[:, 1], combined_data[:, 2], c=combined_labels, cmap='viridis', marker='o')
ax.set_title('3D Clustering of Combined Data')
for center in combined_centers:
    ax.scatter(center[0], center[1], center[2], s=200, c='red', marker='x')

plt.tight_layout()  # 自动调整子图参数
plt.show()
