import json
import uuid
import torch
import torch.nn.functional as F

# 加載提取的特徵 JSON 文件
def load_features(json_file):
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data

# 計算兩個向量的餘弦相似度
def cosine_similarity(v1, v2):
    v1 = torch.tensor(v1, dtype=torch.float32)
    v2 = torch.tensor(v2, dtype=torch.float32)

    # 檢查兩個向量的形狀是否相同
    if v1.shape != v2.shape:
        raise ValueError(f"向量形狀不匹配: v1 {v1.shape}, v2 {v2.shape}")

    # 將向量變成 2D 張量，以符合 cosine_similarity 的要求
    v1 = v1.unsqueeze(0)  # 添加一個維度，使其變為 (1, num_features)
    v2 = v2.unsqueeze(0)  # 添加一個維度，使其變為 (1, num_features)

    # 計算批量餘弦相似度並返回平均值
    return F.cosine_similarity(v1, v2, dim=1).mean().item()

def compare_text_features(item1, item2, text_threshold=0.95):
    try:
        # 比較 VW_address
        address_sim = cosine_similarity(item1['VW_address'], item2['VW_address'])
        if address_sim < text_threshold:
            return False

        # 比較其他文字特徵
        pattern_sim = cosine_similarity(item1['VW_pattern'], item2['VW_pattern']) > 0.9
        size_sim = cosine_similarity(item1['VW_size'], item2['VW_size']) > 0.95
        layer_sim = cosine_similarity(item1['VW_layer'], item2['VW_layer']) > 0.95

        return pattern_sim and size_sim and layer_sim
    except ValueError as e:
        print(f"錯誤: {e}")
        return False

# 計算兩個顏色的相似度（允許一定範圍內的誤差）
def compare_colors(color1, color2, tolerance=50):
    r1, g1, b1 = map(int, color1[4:-1].split(','))
    r2, g2, b2 = map(int, color2[4:-1].split(','))
    return abs(r1 - r2) <= tolerance and abs(g1 - g2) <= tolerance and abs(b1 - b2) <= tolerance

# 比較兩張圖片的物品和顏色
def compare_images(img1_objects, img2_objects, image_threshold=0.5):
    matched_items = 0
    max_items = max(len(img1_objects), len(img2_objects))
    
    # 如果 max_items 為 0，直接返回 False，避免除以 0
    if max_items == 0:
        return False
    
    # 比對物品名稱和顏色，如果相似數達到 image_threshold 則返回 True
    for obj1 in img1_objects:
        for obj2 in img2_objects:
            if obj1['object_label'] == obj2['object_label'] and compare_colors(obj1['color_text'], obj2['color_text']):
                matched_items += 1
                break  # 如果找到相似物品，則不再比對該物品與其他物品
    
    # 確保相似物件數量超過總物品數量的60%
    return matched_items / max_items >= image_threshold

# 比較兩個房屋之間的圖片
def compare_houses_images(item1, item2, image_threshold=0.4):
    img1_list = item1['VP_images']
    img2_list = item2['VP_images']
    similar_images = 0
    
    # 遍歷兩個房屋中的每張圖片，進行逐一比對
    for img1 in img1_list:
        for img2 in img2_list:
            if compare_images(img1['objects'], img2['objects']):
                similar_images += 1
                break  # 如果該圖片相似，則不再比對該圖片與其他圖片的失敗

    # 如果相似的圖片數量佔比超過 image_threshold，則認為這兩個房屋相似
    return similar_images / max(len(img1_list), len(img2_list)) >= image_threshold

def find_similar_items(data, text_threshold=0.8, image_threshold=0.5):
    same_map = {}  # 用來存儲每個房子的 same 編號
    similar_pairs = []  # 存儲相同的房屋 (hid1, hid2)
    same_id_counter = 1  # 自增數字編號起始值

    # 遍歷所有房屋，進行兩兩比對
    for i in range(len(data)):  
        item1 = data[i]
        
        # 如果該房屋已經有相同編號，則跳過比對
        if item1['hid'] in same_map and same_map[item1['hid']] != "none":
            continue
        
        print(f"正在比對房屋 {item1['hid']}")  # 檢查點：列印當前比對的房屋 ID
        found_similar = False

        for j in range(i + 1, len(data)):
            item2 = data[j]

            # 如果該房屋已經有相同編號，則跳過比對
            if item2['hid'] in same_map and same_map[item2['hid']] != "none":
                continue

            # 先進行文字比對
            if compare_text_features(item1, item2, text_threshold):
                
                # 如果文字比對成功，再進行圖片比對
                if compare_houses_images(item1, item2, image_threshold):
                    found_similar = True
                    similar_pairs.append((item1['hid'], item2['hid']))  # 記錄相同的房屋
                    
                    # 檢查是否已有 same_id，沒有則生成
                    if item1['hid'] not in same_map and item2['hid'] not in same_map:
                        same_map[item1['hid']] = same_id_counter
                        same_map[item2['hid']] = same_id_counter
                        print(f"為房屋 {item1['hid']} 和 {item2['hid']} 分配 same_id: {same_id_counter}")  # 列印分配的 same_id
                        same_id_counter += 1  # 編號自增
                    elif item1['hid'] in same_map:
                        same_map[item2['hid']] = same_map[item1['hid']]
                        print(f"為房屋 {item2['hid']} 分配 same_id: {same_map[item1['hid']]}")  # 列印分配的 same_id
                    else:
                        same_map[item1['hid']] = same_map[item2['hid']]
                        print(f"為房屋 {item1['hid']} 分配 same_id: {same_map[item2['hid']]}")  # 列印分配的 same_id
            
        # 如果沒有找到相似房屋，設置 same 為 "none"
        if not found_similar:
            same_map[item1['hid']] = "none"

    # 確保每個 hid 都有 same 編號，若沒有相似房屋則設置為 "none"
    for item in data:
        if item['hid'] not in same_map:
            same_map[item['hid']] = "none"

    return same_map, similar_pairs

# 打印相同房屋對
def print_similar_pairs(similar_pairs):
    print("相同的房屋對：")
    for pair in similar_pairs:
        print(f"房屋 {pair[0]} 和 房屋 {pair[1]} 是相似的")

def main():
    # 加載提取的特徵
    json_file = "C:\\Users\\user\\OneDrive\\桌面\\merged_features_1.json"
    output_json = "C:\\Users\\user\\OneDrive\\桌面\\similar_houses.json"
    
    data = load_features(json_file)
    
    # 找出相似房屋
    same_map, similar_pairs = find_similar_items(data)

    # 將結果保存到新的 JSON 文件
    save_similarities_to_json(same_map, output_json)

    # 打印相同的房屋對
    print_similar_pairs(similar_pairs)

if __name__ == "__main__":
    main()
