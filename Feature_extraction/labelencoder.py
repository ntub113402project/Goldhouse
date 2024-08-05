import pandas as pd
from sklearn.preprocessing import LabelEncoder

# 示例数据
data = {
    'city': ['新竹縣', '台北市', '1234560', 'New', 'Los Angeles']
}
df = pd.DataFrame(data)

# 初始化 LabelEncoder
le = LabelEncoder()

# 进行编码
df['city_encoded'] = le.fit_transform(df['city'])

print(df)