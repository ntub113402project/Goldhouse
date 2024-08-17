import openai
import json
import sys

#* 設定編碼
sys.stdout.reconfigure(encoding='utf-8')

# 设置你的 OpenAI API 密钥
openai.api_key = 'openai-key'

# 读取 JSON 文件
with open('data.json', 'r', encoding='utf-8') as f:
    house_data = json.load(f)

def gpt_analyze_input(hid, message):
    try:
        # 根据 hid 找到目标房屋数据
        target_data = next((item for item in house_data if item['hid'] == hid), None)

        if not target_data:
            return "未找到符合的房屋数据。"

        # 删除 'url' 字段
        if 'url' in target_data:
            del target_data['url']

        # 将过滤后的 JSON 数据转换为字符串
        json_str = json.dumps(target_data, ensure_ascii=False, indent=2)
        prompt = f"Here is some filtered JSON data:\n{json_str}\n\nUser message: {message}\n\nBased on the JSON data and user message, please provide an appropriate response."

        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "你是一個專業的房屋中介助手，能夠回答租屋相關問題，並幫助查找房屋。如果對於使用者的提問不確定如何回答，請表明自己也不確定並要求使用者自行詢問房東"},
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message["content"]
    except Exception as e:
        print(f"Error occurred: {e}")
        return "An error occurred while processing your request."

if __name__ == "__main__":
    target_hid = "16213643"
    question = "請問這間房子可養狗嗎"
    print(f"您查詢的房屋物件為 {target_hid}\n您提問的問題是 {question}")
    answer = gpt_analyze_input(target_hid, question)
    if answer:
        print(f"{answer}")
    else:
        print("没有收到回答，可能发生了错误。")