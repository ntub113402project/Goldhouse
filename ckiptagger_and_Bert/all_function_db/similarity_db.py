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

    if v1.shape != v2.shape:
        raise ValueError(f"向量形狀不匹配: v1 {v1.shape}, v2 {v2.shape}")

    v1 = v1.unsqueeze(0)
    v2 = v2.unsqueeze(0)

    return F.cosine_similarity(v1, v2, dim=1).mean().item()

# 比較文字特徵
def compare_text_features(item1, item2):
    try:
        # 比較 address
        address_sim = cosine_similarity(item1['VW_address'], item2['VW_address'])
        if address_sim < 1:
            return False

        # 比較 pattern
        pattern_sim = cosine_similarity(item1['VW_pattern'], item2['VW_pattern'])
        if pattern_sim <= 0.9:
            return False

        # 比較 size
        size_sim = cosine_similarity(item1['VW_size'], item2['VW_size'])
        if size_sim < 1:
            return False

        # 比較 type
        type_sim = cosine_similarity(item1['VW_type'], item2['VW_type'])
        if type_sim <= 0.8:
            return False

        # 比較 positionround 的 subway
        subway_sim = cosine_similarity(item1['VW_subway'], item2['VW_subway'])
        bus_sim = cosine_similarity(item1['VW_bus'], item2['VW_bus'])
        servicelist_sim = None

        # 比較 positionround 的 bus
        if subway_sim > 0.8:
            subway_pass = True
        else:
            subway_pass = False

        if bus_sim > 0.8:
            bus_pass = True
        else:
            bus_pass = False

        # 比較 servicelist 可用設備
        if item1.get('VW_servicelist') and item2.get('VW_servicelist'):
            servicelist_sim = cosine_similarity(item1['VW_servicelist'], item2['VW_servicelist'])
            servicelist_pass = servicelist_sim > 0.8
        else:
            servicelist_pass = False

        # 如果 subway、bus、servicelist 中有兩個以上通過，則認為相似
        passes = [subway_pass, bus_pass, servicelist_pass].count(True)
        if passes < 2:
            return False

        return True
    except ValueError as e:
        print(f"錯誤: {e}")
        return False

# 比較兩張圖片的物品和顏色
def compare_colors(color1, color2, tolerance=50):
    r1, g1, b1 = map(int, color1[4:-1].split(','))
    r2, g2, b2 = map(int, color2[4:-1].split(','))
    return abs(r1 - r2) <= tolerance and abs(g1 - g2) <= tolerance and abs(b1 - b2) <= tolerance

def compare_images(img1_objects, img2_objects, bert_threshold=0.6, color_tolerance=50):
    matched_items = 0
    max_items = max(len(img1_objects), len(img2_objects))

    if max_items == 0:
        return False

    for obj1 in img1_objects:
        for obj2 in img2_objects:
            bert_similarity = cosine_similarity(obj1['bert_features'], obj2['bert_features'])
            color_similarity = compare_colors(obj1['color_text'], obj2['color_text'], tolerance=color_tolerance)

            if bert_similarity >= bert_threshold and color_similarity:
                matched_items += 1
                break

    return matched_items / max_items >= 0.6

# 查找相似房屋
def find_similar_items(data, text_threshold=0.8, image_threshold=0.5):
    same_map = {}
    similar_pairs = []
    same_id_counter = 1

    for i in range(len(data)):
        item1 = data[i]
        
        if item1['hid'] in same_map and same_map[item1['hid']] != "none":
            continue

        print(f"正在比對房屋 {item1['hid']}")
        found_similar = False

        for j in range(i + 1, len(data)):
            item2 = data[j]

            if item2['hid'] in same_map and same_map[item2['hid']] != "none":
                continue

            if compare_text_features(item1, item2):
                if 'VP_images' not in item1 or 'VP_images' not in item2:
                    continue
                
                for img1 in item1['VP_images']:
                    for img2 in item2['VP_images']:
                        if 'objects' not in img1 or not img1['objects'] or 'objects' not in img2 or not img2['objects']:
                            continue

                        if compare_images(img1['objects'], img2['objects'], image_threshold):
                            found_similar = True
                            similar_pairs.append((item1['hid'], item2['hid']))

                            if item1['hid'] not in same_map and item2['hid'] not in same_map:
                                same_map[item1['hid']] = same_id_counter
                                same_map[item2['hid']] = same_id_counter
                                print(f"為房屋 {item1['hid']} 和 {item2['hid']} 分配 same_id: {same_id_counter}")
                                same_id_counter += 1
                            elif item1['hid'] in same_map:
                                same_map[item2['hid']] = same_map[item1['hid']]
                                print(f"為房屋 {item2['hid']} 分配 same_id: {same_map[item1['hid']]}")
                            else:
                                same_map[item1['hid']] = same_map[item2['hid']]
                                print(f"為房屋 {item1['hid']} 分配 same_id: {same_map[item2['hid']]}")

        if not found_similar:
            same_map[item1['hid']] = "none"

    for item in data:
        if item['hid'] not in same_map:
            same_map[item['hid']] = "none"

    return same_map, similar_pairs

# 將結果存入新的 JSON 文件
def save_similarities_to_json(same_map, output_json):
    result = [{"hid": hid, "same": same} for hid, same in same_map.items()]

    with open(output_json, 'w', encoding='utf-8') as f:
        json.dump(result, f, ensure_ascii=False, indent=4)

    print(f"結果已成功寫入 {output_json}")

# 打印相同房屋對
def print_similar_pairs(similar_pairs):
    print("相同的房屋對：")
    for pair in similar_pairs:
        print(f"房屋 {pair[0]} 和 房屋 {pair[1]} 是相似的")

def main():
    json_file = "C:\\Users\\user\\OneDrive\\桌面\\merged_features.json"
    output_json = "C:\\Users\\user\\OneDrive\\桌面\\similar_houses.json"
    
    data = load_features(json_file)
    same_map, similar_pairs = find_similar_items(data)
    save_similarities_to_json(same_map, output_json)
    print_similar_pairs(similar_pairs)

if __name__ == "__main__":
    main()
