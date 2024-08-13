import os
from itertools import combinations
from PIL import Image
import numpy as np
from skimage.metrics import structural_similarity as ssim
import concurrent.futures

folders_to_process = [
    "C:\\Users\\user\\OneDrive\\桌面\\爬蟲\\gold_house\\8713071",
    "C:\\Users\\user\\OneDrive\\桌面\\爬蟲\\gold_house\\8713071 - 複製",
    "C:\\Users\\user\\OneDrive\\桌面\\爬蟲\\gold_house\\8957187"
]

# 直接使用yolo來做，0.5左右才有我想要的結果
image_similarity_threshold = 0.5
folder_similarity_threshold = 0.5

def preprocess_image(image_path, target_size=(1000, 1000)):
    try:
        image = Image.open(image_path).convert('L')
        image = image.resize(target_size) 
        image = np.array(image) / 255.0   
        return image
    except Exception as e:
        print(f"Error processing image {image_path}: {e}")
        return None

# 利用SSIM結構相似性比較:影像品質的衡量上更能符合人眼對影像品質的判斷。
def calculate_image_similarity(image_path1, image_path2):
    image1 = preprocess_image(image_path1)
    image2 = preprocess_image(image_path2)
    
    if image1 is None or image2 is None:
        return 0.0
    
    similarity_score = ssim(image1, image2, data_range=image1.max() - image1.min())
    
    return similarity_score

# 比較資料夾內圖像
def compare_folders(folder1, folder2):
    images1 = [os.path.join(folder1, file) for file in os.listdir(folder1) if file.endswith(('.jpg', '.jpeg', '.png'))]
    images2 = [os.path.join(folder2, file) for file in os.listdir(folder2) if file.endswith(('.jpg', '.jpeg', '.png'))]
    
    total_pairs = 0
    similarity_sum = 0.0
    
    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = []
        for image1 in images1:
            for image2 in images2:
                futures.append(executor.submit(calculate_image_similarity, image1, image2))
        
        for future in concurrent.futures.as_completed(futures):
            similarity_sum += future.result()
            total_pairs += 1
    
    if total_pairs > 0:
        average_similarity = similarity_sum / total_pairs
    else:
        average_similarity = 0.0
    
    return average_similarity

similar_folders = set()

# 比對
for folder1, folder2 in combinations(folders_to_process, 2):
    folder_similarity = compare_folders(folder1, folder2)
    
    if folder_similarity >= folder_similarity_threshold:
        similar_folders.add(os.path.basename(folder1))
        similar_folders.add(os.path.basename(folder2))

if similar_folders:
    print("Similar folders found:")
    for folder in similar_folders:
        print(folder)
else:
    print("No similar folders found.")
