import json
import sys
sys.stdout.reconfigure(encoding='utf-8')

# 讀取 JSON 檔案
with open('detail2.json', 'r', encoding='utf-8') as file:
    data = json.load(file)

hid_to_delete = [
    63302631, 15877601, 16353588, 16284701, 16075515, 16307794, 16333707,
    16371645, 16362661, 16362755, 16303011, 16331947, 16266633, 16373448,
    16373414, 16218856, 16328108, 16360150, 16319187, 16260453, 16251235,
    16319213, 16363130, 16356910, 16325509, 16256459, 16101533, 16275137,
    16189092, 16370886, 16334015, 16342406, 16370755, 16354880, 16306910,
    16359559, 16337031, 16348859, 16335910, 16319245, 16354249, 16354236,
    16320459, 16364707, 16362548, 16276774, 16319292, 16341944, 16346215,
    16345855, 16342421, 16329147, 10724353, 16252291, 16213945
]

hid_to_delete = [str(hid) for hid in hid_to_delete]

# 刪除 hid 在清單中的資料
filtered_data = [item for item in data if item['hid'] not in hid_to_delete]

# 將結果寫回 JSON 檔案
with open('detail2.json', 'w', encoding='utf-8') as file:
    json.dump(filtered_data, file, ensure_ascii=False, indent=4)

print("刪除成功!")

#! 刪除特定 hid 的資料