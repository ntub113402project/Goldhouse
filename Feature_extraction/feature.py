import pandas as pd
import numpy as np
import sys
import json
import re
from sklearn.feature_selection import SelectKBest, f_regression
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
import matplotlib.pyplot as plt
from geopy.geocoders import Nominatim
import matplotlib.font_manager as fm

#* 設定標準輸出編碼
sys.stdout.reconfigure(encoding='utf-8')

#! 參數配置
address_geopy_start = False #* Use geopy to evaluate address
address_tfidf_start = False #* Use tfidf to evaluate address
serviceCount_start = False #* Use serviceCount to evaluate servicelist
servicelist_partition_start = True #* partition each of device as a feature


#* 讀取 JSON 文件
with open('data.json', encoding='utf-8') as f:
    data = json.load(f)
data_length = len(data)

#* 讀取 cn_stopwords.txt 分詞表
with open('cn_stopwords.txt', encoding='utf-8') as f:
    chinese_stop_words = f.read().splitlines()

#* dataframe 資料處理
houses = []
devices = ["冰箱", "洗衣機", "電視", "冷氣", "熱水器", "床", "衣櫃", "第四台", "網路", "天然瓦斯", "沙發", "桌椅", "陽台", "電梯", "車位"]
for item in data:
    house = {
        'hid':item['hid'], 
        'title':item['houseinfo']['title'],
        'pattern':item['houseinfo']['pattern'],
        'size':item['houseinfo']['size'],
        'layer':item['houseinfo']['layer'],
        'type':item['houseinfo']['type'],
        'price':item['houseinfo']['price'],
        'address':item['positionround']['address'], 
        'subway':item['positionround']['subway'], #list
        'bus':item['positionround']['bus'], #list
        'servicelist':item['servicelist'], #list
        'description':item['remark']['content'] #list
    }
    houses.append(house)

#* 轉換為 DataFrame
df = pd.json_normalize(houses)

#* 檢查 DataFrame 結構
print(df.info())
print(df.head())

#todo 資料處理 (TEXT -> value)
#* price
df['price'] = np.floor(df['price'] / 500).astype(int)
print("price complete")

le_title = LabelEncoder() #* title
df['title'] = le_title.fit_transform(df['title'])
print("title complete")

le_pattern = LabelEncoder() #* pattern
df['pattern'] = le_pattern.fit_transform(df['pattern'])
print("pattern complete")

type_mapping = { #*type
    '電梯大樓': 1,
    '公寓': 2,
    '透天厝': 3,
    '別墅': 4,
    # 你可以根據需要擴展到其他類型
}
df['type'] = df['type'].map(type_mapping)

# le_type = LabelEncoder() #* type
# df['type'] = le_type.fit_transform(df['type'])
# print("type complete")

#* size
df['size'] = df['size'].apply(lambda x: float(x.replace('坪', '').strip()))
print("size complete")

#* layer
# def extract_floor_info(layer):
#     try:
#         # 常规情况
#         if '/' in layer:
#             current, total = layer.split('/')
#             current = current.replace('F', '').strip()
#             total = total.replace('F', '').strip()
#             current = int(current) if current.isdigit() else np.nan
#             total = int(total) if total.isdigit() else np.nan
#             return current, total
#         else:
#             return np.nan, np.nan
#     except (ValueError, AttributeError, IndexError):
#         return np.nan, np.nan
def extract_floor_info(layer):
    try:
        if '/' in layer:
            current, total = layer.split('/')

            #* 處理 total
            total = int(total.replace('F', '').strip()) if total.replace('F', '').isdigit() else np.nan

            #* 處理 current
            if "~" in current or current == "整棟": #* "整棟" or "~" 歸類為 0
                current = 0
            elif current == "頂層加蓋":
                current = total + 1
            elif "B" in current:
                current = -int(current.replace('B', '').strip()) if current[1:].isdigit() else np.nan
            elif "F" in current:
                current = int(current.replace('F', '').strip()) if current.replace('F', '').isdigit() else np.nan
            else:
                current = np.nan

            return current, total
        else:
            return np.nan, np.nan #意外情況
    except (ValueError, AttributeError, IndexError):
        return np.nan, np.nan #意外情況
    
df['Layer_Current'], df['Layer_Total'] = zip(*df['layer'].apply(extract_floor_info))
print("layer complete")

#* servicelist
def servicelist_to_count(servicelist):
    try:
        return sum(1 for service in servicelist if service['avaliable'])
    except Exception as e:
        return 0

def servicelist_to_features(servicelist):
    service_dict = {name: 0 for name in devices}
    for service in servicelist:
        #* 錯誤字串處理
        device_name = re.sub(r'\d+陽台', '陽台', service['device'])
        device_name = re.sub(r'.*車位', '車位', device_name)
        if service['avaliable']:
            service_dict[device_name] = 1
        else:
            service_dict[device_name] = 0
    return pd.Series(service_dict)

if servicelist_partition_start:
    servicelist_df = df['servicelist'].apply(servicelist_to_features)
    df = pd.concat([df, servicelist_df], axis=1)
if serviceCount_start:
    df['ServiceCount'] = df['servicelist'].apply(servicelist_to_count)
print("servicelist complete")

#* address (TF-IDF / Geopy)
#TF-TDF
if address_tfidf_start:
    vectorizer = TfidfVectorizer(stop_words=chinese_stop_words)
    address_matrix = vectorizer.fit_transform(df['address'])
    address_mean = address_matrix.mean(axis=1).A1
    df['address_tftdf'] = address_mean
    print('address-TF-TDF complete')

#Geopy
if address_geopy_start:
    geolocator = Nominatim(user_agent="geoapiExercises")
    address_geopy_fail = 0
    address_geopy_success = 0
    def get_lat_lon(address):
        global address_geopy_fail, address_geopy_success
        try:
            location = geolocator.geocode(address)
            address_geopy_success+=1
            print(f"完成度:{(address_geopy_success+address_geopy_fail)}/{data_length}, Success:{address_geopy_success}, fail:{address_geopy_fail}")
            return location.latitude, location.longitude
        except:
            address_geopy_fail+=1
            print(f"完成度:{(address_geopy_success+address_geopy_fail)}/{data_length}, Success:{address_geopy_success}, fail:{address_geopy_fail}")
            return 0, 0
    df['Latitude'], df['Longitude'] = zip(*df['address'].apply(get_lat_lon))
    print(f"address-Geopy complete, Success rate:{address_geopy_success/data_length}")

#* description
# 處理文本特徵（Description）
df['description'] = df['description'].apply(lambda x: ' '.join(x))
vectorizer = TfidfVectorizer(stop_words=chinese_stop_words)
description_matrix = vectorizer.fit_transform(df['description'])

# 計算每個描述的平均TF-IDF值
description_mean = description_matrix.mean(axis=1).A1
df['description'] = description_mean
print("description complete")

#* subway
df['subway'] = df['subway'].apply(lambda x: ' '.join(x))
vectorizer = TfidfVectorizer(stop_words=chinese_stop_words)
subway_matrix = vectorizer.fit_transform(df['subway'])
df['subway'] = subway_matrix.mean(axis=1).A1

#* bus
df['bus'] = df['bus'].apply(lambda x: ' '.join(x))
vectorizer = TfidfVectorizer(stop_words=chinese_stop_words)
bus_matrix = vectorizer.fit_transform(df['bus'])
df['bus'] = bus_matrix.mean(axis=1).A1

#todo 特徵提取
#* 準備特徵和目標變量
X = df.drop(['hid', 'servicelist', 'address', 'layer'], axis=1) #需要移除的項目
y = df['price']

#* 檢查特徵矩陣和目標變量
print(X.head())
print(y.head())

# 确保所有列都是数值类型
print(X.dtypes)

# 填充 NaN 值
X = X.fillna(X.mean())

# 標準化特徵
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# 使用SelectKBest選擇k個最重要的特徵
k = 100  # 你可以根據需求調整k值
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

# 指定中文字体
plt.rcParams['font.sans-serif'] = ['Microsoft YaHei'] # 选择黑体
plt.rcParams['axes.unicode_minus'] = False # 解决保存图像时负号显示为方块的问题

# 可視化特徵重要性
plt.figure(figsize=(12, 8))
plt.barh(importance_df['Feature'], importance_df['Importance'])
plt.xlabel('Importance')
plt.title('Feature Importance')
plt.gca().invert_yaxis()
plt.show()