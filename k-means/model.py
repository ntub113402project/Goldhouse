import numpy as np
import math
import os
import json
import joblib
import matplotlib.pyplot as plt
from sklearn.cluster import MiniBatchKMeans
from sklearn.impute import SimpleImputer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import StandardScaler
from mpl_toolkits.mplot3d import Axes3D
import sys
import pandas as pd
import numbers

#* 设置输出编码为 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

#! 參數配置 for kmeans
stop_words_file = 'cn_stopwords.txt' #* 分詞表 path
model_file = 'kmeans_model.pkl' #* 模型 path
model_data_file = 'model_data.json' #* 模型資料 path
new_data_file = 'data.json' #* 新增資料 path
number_of_cluster = 8 #* 特徵數量
graph3D_features =[] #* 特徵 3D 映射 (選三類)
#? 資料型態：[hid, f1, f2, f3, ...]


#* 選擇處理 Nan 的流程 (choose 1)


#todo load file (讀取模型, 模型資料, 新增資料, 分詞表)
#* 讀取 cn_stopwords.txt 分詞表
# with open(stop_words_file, encoding='utf-8') as f:
#     chinese_stop_words = f.read().splitlines()

#* 讀取模型
if os.path.exists(model_file):
    kmeans_loaded = joblib.load(model_file)
    print("model exists")
else:
    print("model does not exists")

#* 讀取模型資料
if os.path.exists(model_data_file):
    with open(model_data_file, encoding='utf-8') as f:
        model_data = json.load(f)
    print("model data exists")
else:
    model_data = []
    print("model data does not exists")

#* 讀取要新增的資料
if os.path.exists(new_data_file):
    with open(new_data_file, encoding='utf-8') as f:
        new_data = json.load(f)
    if new_data == [] or not new_data:
        print(f"{new_data_file} is empty or empty list")
        new_data = []
    else:
        print("Add new data to model")

#* 將已存在的資料去除, 不納入模型訓練
existing_hids = {item[0] for item in model_data}  # 提取已有模型資料的 hid
new_data = [item for item in new_data if item['hid'] not in existing_hids]  # 去除已有的 hid
print(f"Adding {len(new_data)} new data to model")

#todo 資料處理
#* 處理 layer 分割成 Current and Total
def extract_floor_info(layer):
    try:
        if '/' in layer:
            current, total = layer.split('/')
            current = current.replace('F', '').strip()
            total = total.replace('F', '').strip()
            current = int(current) if current.isdigit() else np.nan
            total = int(total) if total.isdigit() else np.nan
            return current, total
        else:
            return 0, 0 #意外情況
    except (ValueError, AttributeError, IndexError):
        return 0, 0 #意外情況

#* 處理 servicelist
def servicelist_to_vector(servicelist):
    service_names = ["冰箱", "洗衣機", "電視", "冷氣", "熱水器", "床", "衣櫃", "第四台", "網路", "天然瓦斯", "沙發", "桌椅", "陽台", "電梯", "車位"]
    service_dict = {name: 0 for name in service_names}
    for service in servicelist:
        if service['avaliable']:
            service_dict[service['device']] = 1
    return list(service_dict.values())

#* 處理文字特徵 address, description, title
# vectorizer = TfidfVectorizer(stop_words=chinese_stop_words)
# address_texts = [item['positionround']['address'] for item in new_data]
# description_texts = [' '.join(item['remark']['content']) if isinstance(item['remark']['content'], list) else item['remark']['content'] for item in new_data]

# title_texts = [item['houseinfo']['title'] for item in new_data]
# address_matrix = vectorizer.fit_transform(address_texts).toarray()
# description_matrix = vectorizer.fit_transform(description_texts).toarray()
# title_matrix = vectorizer.fit_transform(title_texts).toarray()
# print(description_matrix)

#* 轉換資料為 datalist
datalist = []
for i, item in enumerate(new_data):
    hid = item['hid']
    price = float(item['houseinfo']['price'])
    size = float(item['houseinfo']['size'].replace('坪', '').strip())
    layer_current, layer_total = extract_floor_info(item['houseinfo']['layer'])
    servicelist_vector = servicelist_to_vector(item['servicelist'])

    #* feature selected pattern：[hid, f1, f2, f3, ...]
    feature_vector = [hid, price, size, layer_current, layer_total] + servicelist_vector  # 展平 servicelist_vector
    # feature_vector.extend(address_matrix[i])
    # feature_vector.extend(description_matrix[i])
    # feature_vector.extend(title_matrix[i])
    datalist.append(feature_vector)

#* 更新 model data
model_data.extend(datalist)

#* 確保datalist長度相同，並且找出包含 Nan 的資料
nan_data_count = 0
max_length = max(len(data) for data in model_data)
for data in model_data:
    if len(data) < max_length:
        data.extend([math.nan] * (max_length - len(data)))  #* 填充缺失的部分
    if any(math.isnan(elem) if isinstance(elem, float) else False for elem in data): #* 檢查資料中是否含有 Nan
        nan_data_count += 1
        #print(f"包含 NaN 的資料：{data}, {len(data)}")

print(f"共有 {nan_data_count} 筆資料包含 NaN")

#* 轉換為 numpy, 提取特徵部分
feature_data = np.array([data[1:] for data in model_data])

#! 參數配置 for Nan replacement
#* 選擇每個特徵填充 Nan 的方法 (不包含 hid column)
#* mode, mean, median, zero, constant
nanlist = [0, 0, 'mean', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

#* 檢查 nanlist 的長度
if len(nanlist) != feature_data.shape[1]:
    raise ValueError("nanlist 的长度必须与特征数量相同")

#* Nan 處理
processed_features = []

for i in range(feature_data.shape[1]):
    column = feature_data[:, i]
    strategy = nanlist[i]
    
    #* 檢查 Nan 是否存在
    if not pd.isna(column).any():
        processed_features.append(column)
        continue

    if strategy == 'mean': #* 平均數
        col_data = column.astype(np.float64)
        imputer = SimpleImputer(strategy='mean')
        col_filled = imputer.fit_transform(col_data.reshape(-1, 1)).flatten()
    elif strategy == 'median': #* 中位數
        col_data = column.astype(np.float64)
        imputer = SimpleImputer(strategy='median')
        col_filled = imputer.fit_transform(col_data.reshape(-1, 1)).flatten()
    elif strategy == 'mode': #* 眾數
        col_data = column.astype(np.float64)
        imputer = SimpleImputer(strategy='most_frequent')
        col_filled = imputer.fit_transform(col_data.reshape(-1, 1)).flatten()
    elif isinstance(strategy, numbers.Number): #* 常數
        fill_value = strategy
        col_data = column.astype(np.float64)
        imputer = SimpleImputer(strategy='constant', fill_value=fill_value)
        col_filled = imputer.fit_transform(col_data.reshape(-1, 1)).flatten()
    elif strategy == 'zero': #* 0
        col_data = column.astype(np.float64)
        col_filled = np.nan_to_num(col_data, nan=0)
    else:
        raise ValueError(f"未知的策略 '{strategy}' 在第 {i+1} 列。")
    
    processed_features.append(col_filled)

# 合并处理后的特征数据
feature_data = np.column_stack(processed_features)

#* 训练 MiniBatchKMeans 模型
kmeans_loaded = MiniBatchKMeans(n_clusters=number_of_cluster, random_state=42, batch_size=10)
kmeans_loaded.fit(feature_data)

#* Save model 
joblib.dump(kmeans_loaded, model_file)
print(f"Model saved to", model_file)

#* Save model data
with open(model_data_file, 'w', encoding='utf-8') as f:
    json.dump(model_data, f)
print("Model data saved to", model_data_file)

#! 參數配置 for 可視化
First_index = 1  # price 的索引位置
Second_index = 2  # size 的索引位置
Third_index = 3  # layer_current 的索引位置

#* 準備可視化數據
x = feature_data[:, First_index]
y = feature_data[:, Second_index]
z = feature_data[:, Third_index]

#* 获取聚类标签
labels = kmeans_loaded.labels_

#* 3D 可視化
fig = plt.figure(figsize=(10, 8))
ax = fig.add_subplot(111, projection='3d')
scatter = ax.scatter(x, y, z, c=labels, cmap='viridis', marker='o')
ax.set_xlabel('Price')
ax.set_ylabel('Size')
ax.set_zlabel('Current Floor')
ax.set_title('3D Clustering Visualization')
plt.show()
