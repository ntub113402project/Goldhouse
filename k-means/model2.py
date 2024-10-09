import mysql.connector
import numpy as np
import sys
import os
import json
import joblib
from sklearn.cluster import KMeans

#! 使用須知
#* 1. 用於模型訓練的資料必須和物件資料匹配才能做 mapping
#* 2. database table 必須包含 cluster(物件對應的cluster), kmeans_model_sample(是否用於模型調整) 欄位
#* 3. 模型必須先訓練完後放入資料夾中, 程式才能夠做 mapping
#* 4. 提供四個功能：mapping data, retrain model, train model, clean cluster
#* 5. 每一筆 datalist 第一欄必須為 hid, hid 並不會納入 kmeans 計算, 但會用於與資料庫溝通
#* 6. 原始資料和模型一定要放在同一個資料夾下才能運作, 刪掉會出事

#todo 輸出編碼 UTF-8
sys.stdout.reconfigure(encoding='utf-8')

#! 參數
number_of_clusters = 140 #* 分群個數
kmeans_model_path = 'kmeans_model.pkl' #* kmeans model 路徑
origin_data_path = 'data2.json' #* 原始資料路徑

#todo connect to database
mydb = mysql.connector.connect(
    host="localhost",
    user="root",
    password="123456",
    database="gh_members",
    connection_timeout=600,
    get_warnings=True
)
cursor = mydb.cursor()

#todo 處理 layer 分割成 Current and Total
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
                current = total + 1 if total != np.nan else np.nan
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

#todo 抓取 DB 中的特定資料組成模型可接受的 result
def get_data(hid):
    query = "SELECT hid, price, size, layer FROM new_housedetail WHERE hid = %s"
    cursor.execute(query, (hid,))  #* 用 %s 可以防止 SQL 注入攻擊
    result = cursor.fetchone()

    if result:
        layer_current, layer_total = extract_floor_info(result[3])
        size = float(result[2].replace('坪', '').strip())
        result_list = [result[0], result[1], size, layer_current, layer_total]
        return result_list 
    else:
        return {"message": "No data found for given ID"}
    #* result_list：[hid, price, size, layer_current, layer_total]

#todo mapping data to satisfied cluster
def mapping_to_cluster(hid_list): #* Given hid list
    #* 讀取模型
    if os.path.exists(kmeans_model_path):
        kmeans_model = joblib.load(kmeans_model_path)
        print("model exists")
    else:
        print(f"model：{kmeans_model_path} does not exists")

    #* mapping cluster
    for hid in hid_list:
        data = get_data(hid)
        hid = data[0]
        feature_data = data[1:]
        cluster = int(kmeans_model.predict(np.array(feature_data).reshape(1, -1))[0]) #* mapping
        cursor.execute("UPDATE new_housedetail SET cluster = %s WHERE hid = %s", (cluster, hid))
        mydb.commit()
        print(f"Success mapping {hid} to cluster {cluster}")
        
#todo add new data to retrain model
def retrain_kmeans_model(hid_list): #* Given hid list
    #* 讀取原始資料
    if os.path.exists(origin_data_path):
        with open(origin_data_path, encoding='utf-8') as f:
            origin_data = json.load(f)
        print("原始資料載入")
    else:
        raise FileNotFoundError(f"原始資料不存在：{origin_data_path}")
    
    #* 處理資料
    datalist = []
    for data in origin_data:
        layer_current, layer_total = extract_floor_info(data[3])
        size = float(data[2].replace('坪', '').strip())
        datalist.append([data[1],size,layer_current,layer_total])

    #* 開始重新訓練模型
    number_of_invaild_hid = 0
    #* 將標註為模型樣本的資料 納入模型訓練
    cursor.execute("SELECT hid FROM new_housedetail WHERE kmeans_model_sample = 1")
    hid_list2 = [row[0] for row in cursor.fetchall()]
    combined_hid_list = list(set(hid_list + hid_list2)) #* 去除重複資料
    for hid in combined_hid_list:
        data = get_data(hid)
        if isinstance(data, dict) and 'message' in data:
            print(f"hid:{hid} not found")
            number_of_invaild_hid += 1
            continue
        #* 將新增的資料 標註為模型資料
        cursor.execute("UPDATE new_housedetail SET kmeans_model_sample = 1 WHERE hid = %s", (hid,))
        mydb.commit()
        datalist.append(data[1:])
    print(f"有 {number_of_invaild_hid} 筆 hid 不存在資料庫中")

    #* 重新訓練 kmeans 模型
    kmeans_data = np.array(datalist)
    kmeans_model = KMeans(n_clusters=number_of_clusters, random_state=42)
    kmeans_model.fit(kmeans_data)

    #* 保存新的模型
    joblib.dump(kmeans_model, kmeans_model_path)
    print(f"模型重新訓練完成，並已保存到：{kmeans_model_path}")

    #* 使用新模型重新對資料進行 cluster mapping
    cursor.execute("SELECT hid FROM new_housedetail WHERE kmeans_model_sample = 1 OR cluster IS NOT NULL")
    rows = cursor.fetchall()
    hid_list = [row[0] for row in rows]
    mapping_to_cluster(hid_list)

    # #* 使用新模型更新資料庫中的 cluster 欄位（只對資料庫中的資料進行 mapping）
    # origin_data_length = len(origin_data)
    # datalist = datalist[origin_data_length:]

    # #* 使用新模型重新對資料進行 cluster mapping
    # cluster_labels = kmeans_model.predict(np.array(datalist))
    # for hid, cluster in zip(hid_mapping, cluster_labels):
    #     cursor.execute("UPDATE new_housedetail SET cluster = %s WHERE hid = %s", (int(cluster), hid))
    # mydb.commit()
    # print("資料的 cluster 標註已更新到資料庫中。")

#todo clean model for all data (模型刪除, 所有資料與kmeans相關的欄位回復到預設狀態)
def clean_cluster_all():
    cursor.execute("UPDATE new_housedetail SET cluster = NULL")
    cursor.execute("UPDATE new_housedetail SET kmeans_model_sample = 0")
    mydb.commit()
    print("除所有資料的 cluster, kemans_model_sample 已回到原始狀態")

    if os.path.exists(kmeans_model_path):
        os.remove(kmeans_model_path)
        print(f"模型檔案 {kmeans_model_path} 已刪除。")
    else:
        print(f"模型檔案 {kmeans_model_path} 不存在。")

#todo train new model
def train_kmeans_model():
    #* 讀取原始資料
    if os.path.exists(origin_data_path):
        with open(origin_data_path, encoding='utf-8') as f:
            origin_data = json.load(f)
        print("原始資料載入")
    else:
        raise FileNotFoundError(f"原始資料不存在：{origin_data_path}")
    
    #* 處理資料
    datalist = []
    for data in origin_data:
        layer_current, layer_total = extract_floor_info(data[3])
        size = float(data[2].replace('坪', '').strip())
        datalist.append([data[0],data[1],size,layer_current,layer_total])

    #* 開始訓練原始 kmeans 模型
    kmeans_data = np.array([features[1:] for features in datalist])
    kmeans_model = KMeans(n_clusters=number_of_clusters, random_state=42)
    kmeans_model.fit(kmeans_data)

    #* 保存模型
    joblib.dump(kmeans_model, kmeans_model_path)
    print(f"模型訓練完成")

#todo select all hid without mapping
def unmapping_hid_list():
    cursor.execute("SELECT hid FROM new_housedetail WHERE cluster IS NULL")
    hid_list = [row[0] for row in cursor.fetchall()]
    return hid_list
    
#todo select all hid with kmeans_model_sample=0
def unmodel_hid_list():
    cursor.execute("SELECT hid FROM new_housedetail WHERE kmeans_model_sample = 0")
    hid_list = [row[0] for row in cursor.fetchall()]
    return hid_list

#todo mapping mapping data (not in database) to satisfied cluster
#* 需要提供所有特徵資料在 list 中, 並且一次只能識別一筆資料. 並且不會有資料庫存取
def mapping_to_cluster2(data): #* Given a data with needed features
    #* 讀取模型
    if os.path.exists(kmeans_model_path):
        kmeans_model = joblib.load(kmeans_model_path)
        print("model exists")
    else:
        print(f"model：{kmeans_model_path} does not exists")

    #* mapping cluster
    hid = data[0]
    layer_current, layer_total = extract_floor_info(data[3])
    size = float(data[2].replace('坪', '').strip())
    feature_data = [data[1],size,layer_current,layer_total]
    cluster = int(kmeans_model.predict(np.array(feature_data).reshape(1, -1))[0]) #* mapping
    print(f"Success mapping {hid} to cluster {cluster}")
    return cluster

#todo main
mapping_to_cluster2([
        "16238818",
        31200,
        "33.46坪",
        "5F/5F"
    ])
# clean_cluster_all()
# train_kmeans_model()
# retrain_kmeans_model(unmodel_hid_list())

# clean_cluster_all()
# mapping_to_cluster(unmapping_hid_list())