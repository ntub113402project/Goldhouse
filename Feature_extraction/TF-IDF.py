import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from sklearn.feature_extraction.text import TfidfVectorizer

# 假設有一個 DataFrame df，其中包含房屋描述
df = pd.DataFrame({
    'Description': [
        'Spacious modern house in the heart of the city.',
        'Modern and spacious house located centrally.',
        'Charming house with garden and garage in a quiet neighborhood.',
        'Luxurious apartment with a stunning view of the skyline.',
        'Cozy cottage with a beautiful backyard and close to amenities.'
    ]
})

# 創建 TfidfVectorizer 物件
vectorizer = TfidfVectorizer(stop_words='english')

# 計算 TF-IDF 矩陣
tfidf_matrix = vectorizer.fit_transform(df['Description'])

# 將 TF-IDF 矩陣轉換為 DataFrame，並顯示特徵名稱
tfidf_df = pd.DataFrame(tfidf_matrix.toarray(), columns=vectorizer.get_feature_names_out())

# 打印 TF-IDF DataFrame
pd.set_option('display.max_columns', None)
print(tfidf_df)

# 創建熱圖
plt.figure(figsize=(12, 8))
sns.heatmap(tfidf_df, annot=True, cmap='YlGnBu', cbar=True, linewidths=.5)
plt.title('TF-IDF Heatmap')
plt.xlabel('Words')
plt.ylabel('Descriptions')
plt.xticks(rotation=45, ha='right')
plt.show()
