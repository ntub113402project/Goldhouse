import numpy as np
import matplotlib.pyplot as plt
from sklearn.cluster import KMeans
from scipy.spatial import Voronoi, voronoi_plot_2d
from mpl_toolkits.mplot3d import Axes3D

# 生成隨機數據
np.random.seed(99)
data = np.random.rand(1000, 3)  # 三維數據

# 取前兩個特徵
data_2d = data[:, :2]

# 不設置 random_state
kmeans1 = KMeans(n_clusters=3)
kmeans1.fit(data)
labels1 = kmeans1.labels_
centers1 = kmeans1.cluster_centers_

# 設置 random_state=42
kmeans2 = KMeans(n_clusters=3, random_state=42)
kmeans2.fit(data)
labels2 = kmeans2.labels_
centers2 = kmeans2.cluster_centers_

# 設置 random_state=99
kmeans3 = KMeans(n_clusters=3, random_state=99)
kmeans3.fit(data)
labels3 = kmeans3.labels_
centers3 = kmeans3.cluster_centers_

# 創建 Voronoi 圖
vor1 = Voronoi(centers1[:, :2])
vor2 = Voronoi(centers2[:, :2])
vor3 = Voronoi(centers3[:, :2])

# 視覺化結果
fig = plt.figure(figsize=(18, 10))

# 不設置 random_state - 2D圖
ax1 = fig.add_subplot(231)
ax1.scatter(data_2d[:, 0], data_2d[:, 1], c=labels1, cmap='viridis', marker='o')
ax1.scatter(centers1[:, 0], centers1[:, 1], s=200, c='red', marker='x')
voronoi_plot_2d(vor1, ax=ax1, show_vertices=False, line_colors='orange', line_width=2, line_alpha=0.6, point_size=2)
ax1.set_title('2D Without random_state')

# 設置 random_state=42 - 2D圖
ax2 = fig.add_subplot(232)
ax2.scatter(data_2d[:, 0], data_2d[:, 1], c=labels2, cmap='viridis', marker='o')
ax2.scatter(centers2[:, 0], centers2[:, 1], s=200, c='red', marker='x')
voronoi_plot_2d(vor2, ax=ax2, show_vertices=False, line_colors='orange', line_width=2, line_alpha=0.6, point_size=2)
ax2.set_title('2D With random_state=42')

# 設置 random_state=99 - 2D圖
ax3 = fig.add_subplot(233)
ax3.scatter(data_2d[:, 0], data_2d[:, 1], c=labels3, cmap='viridis', marker='o')
ax3.scatter(centers3[:, 0], centers3[:, 1], s=200, c='red', marker='x')
voronoi_plot_2d(vor3, ax=ax3, show_vertices=False, line_colors='orange', line_width=2, line_alpha=0.6, point_size=2)
ax3.set_title('2D With random_state=99')

# 不設置 random_state - 3D圖
ax4 = fig.add_subplot(234, projection='3d')
scatter1 = ax4.scatter(data[:, 0], data[:, 1], data[:, 2], c=labels1, cmap='viridis', marker='o')
ax4.set_title('3D Without random_state')
for center in centers1:
    ax4.scatter(center[0], center[1], center[2], s=200, c='red', marker='x')

# 設置 random_state=42 - 3D圖
ax5 = fig.add_subplot(235, projection='3d')
scatter2 = ax5.scatter(data[:, 0], data[:, 1], data[:, 2], c=labels2, cmap='viridis', marker='o')
ax5.set_title('3D With random_state=42')
for center in centers2:
    ax5.scatter(center[0], center[1], center[2], s=200, c='red', marker='x')

# 設置 random_state=99 - 3D圖
ax6 = fig.add_subplot(236, projection='3d')
scatter3 = ax6.scatter(data[:, 0], data[:, 1], data[:, 2], c=labels3, cmap='viridis', marker='o')
ax6.set_title('3D With random_state=99')
for center in centers3:
    ax6.scatter(center[0], center[1], center[2], s=200, c='red', marker='x')

plt.show()

# 檢查結果是否一致
print("Without random_state:")
print(labels1[:10])

print("\nWith random_state=42:")
print(labels2[:10])

print("\nWith random_state=99:")
print(labels3[:10])
