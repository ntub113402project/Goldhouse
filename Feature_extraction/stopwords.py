import pandas as pd
import jieba
from sklearn.feature_extraction.text import TfidfVectorizer
import sys

sys.stdout.reconfigure(encoding='utf-8')

# 示例中文文本数据
texts = [
    "狐狸和狗在田野里跑来跑去",
    "快速的狐狸跳过懒惰的狗",
    "这只狗非常懒惰，而那只狐狸很快"
]

# 读取停用词表文件
with open('cn_stopwords.txt', encoding='utf-8') as f:
    stop_words = f.read().splitlines()

# 使用 jieba 进行中文分词
texts_segmented = [' '.join(jieba.cut(text)) for text in texts]

print(texts_segmented)
# 初始化 TfidfVectorizer 并设置自定义停用词列表
vectorizer = TfidfVectorizer(stop_words=stop_words)

# 计算 TF-IDF 特征
tfidf_matrix = vectorizer.fit_transform(texts_segmented)

# 将 TF-IDF 特征转换为 DataFrame
tfidf_df = pd.DataFrame(tfidf_matrix.toarray(), columns=vectorizer.get_feature_names_out())

# 打印结果
print(tfidf_df)
