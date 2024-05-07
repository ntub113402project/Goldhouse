import numpy as np
import jieba

# posseg模塊
import jieba.posseg as pseg

# 測試語句
text = "張惠妹在演唱會演唱三天三夜"

# 加詞前的分詞
seg_list = jieba.cut(text, cut_all=False)
print("加詞前的分詞: " + "/ ".join(seg_list))  

# 加詞、加詞性
jieba.add_word('三天三夜',freq=100,tag="N")
jieba.add_word('演唱會',freq=100,tag="N")

seg_list = jieba.cut(text, cut_all=False)
print("加詞後的分詞: " + "/ ".join(seg_list))  

# 詞性(POS)標註
words = jieba.posseg.cut(text)     
for word, flag in words:
    print(f'{word} {flag}')