import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import LogisticRegression, LassoCV
from sklearn.feature_selection import RFE, SelectKBest, chi2
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score

# 生成虛擬數據
np.random.seed(42)
data = pd.DataFrame({
    'Age': np.random.randint(18, 70, 1000),
    'Gender': np.random.choice(['Male', 'Female'], 1000),
    'Geography': np.random.choice(['France', 'Germany', 'Spain'], 1000),
    'CreditScore': np.random.randint(300, 850, 1000),
    'Balance': np.random.uniform(0, 100000, 1000),
    'HasCreditCard': np.random.choice([0, 1], 1000),
    'IsActiveMember': np.random.choice([0, 1], 1000),
    'EstimatedSalary': np.random.uniform(20000, 150000, 1000),
    'Exited': np.random.choice([0, 1], 1000)
})

# 數據預處理
le = LabelEncoder()
data['Gender'] = le.fit_transform(data['Gender'])
data['Geography'] = le.fit_transform(data['Geography'])

X = data.drop('Exited', axis=1)
y = data['Exited']

# 篩選法：卡方檢驗
skb = SelectKBest(score_func=chi2, k=5)
skb.fit(X, y)
skb_features = skb.get_support(indices=True)
skb_scores = skb.scores_

# 包裝法：遞歸特徵消除
logreg = LogisticRegression(max_iter=1000)
rfe = RFE(estimator=logreg, n_features_to_select=5, step=1)
rfe.fit(X, y)
rfe_features = rfe.get_support(indices=True)
# 使用 ranking_ 獲取特徵重要性分數
rfe_ranking = rfe.ranking_
rfe_scores = 1 / rfe_ranking  # 排名越高，重要性越高

# 嵌入法：LASSO
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)
lasso = LassoCV(cv=5)
lasso.fit(X_scaled, y)
lasso_features = np.where(lasso.coef_ != 0)[0]
lasso_scores = lasso.coef_[lasso_features]

# 可視化特徵選取結果
feature_names = X.columns
skb_selected_features = feature_names[skb_features]
rfe_selected_features = feature_names[rfe_features]
lasso_selected_features = feature_names[lasso_features]

plt.figure(figsize=(15, 5))

plt.subplot(1, 3, 1)
plt.barh(skb_selected_features, skb_scores[skb_features])
plt.title('Chi-Square Scores')
plt.xlabel('Score')

plt.subplot(1, 3, 2)
plt.barh(rfe_selected_features, rfe_scores[rfe_features])
plt.title('RFE Selected Features')
plt.xlabel('Ranking (1 / Score)')

plt.subplot(1, 3, 3)
plt.barh(lasso_selected_features, lasso_scores)
plt.title('LASSO Selected Features')
plt.xlabel('Coefficient')

plt.tight_layout()
plt.show()

# 訓練模型
selected_features = list(set(skb_selected_features).union(set(rfe_selected_features)).union(set(lasso_selected_features)))
X_selected = X[selected_features]

X_train, X_test, y_train, y_test = train_test_split(X_selected, y, test_size=0.3, random_state=42)

model = LogisticRegression(max_iter=1000)
model.fit(X_train, y_train)
y_pred = model.predict(X_test)

# 評估模型
accuracy = accuracy_score(y_test, y_pred)
f1 = f1_score(y_test, y_pred)

print(f'Accuracy: {accuracy:.2f}')
print(f'F1 Score: {f1:.2f}')
