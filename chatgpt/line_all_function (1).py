#pip install openai==0.28
#pip install line-bot-sdk==1.20.0
#pip install pyngrok
#pip install Flask-Session
from pyngrok import ngrok
import openai
from flask import Flask, request, abort
from linebot import LineBotApi, WebhookHandler
from linebot.exceptions import InvalidSignatureError
from linebot.models import TextSendMessage, MessageEvent, TextMessage
import secrets
import re
from py2neo import Graph

# 設定 OpenAI API 金鑰
openai.api_key = 

# 設定 Neo4j 連接
graph = Graph("bolt://localhost:7687", auth=("neo4j", "12345678"))

# Line Bot API
line_bot_api = LineBotApi('roSdGg4QLioRqB12KU6oTUiv08omTL28Vc2arQ2MrfPYSyDW0uKqZJj6B0TcZPBuXUpCKu4dbAu6hA5b4A4JoBS57j202fZ/zl2BFjjKVAWZKz1W0atGTVYNVkpQL9R5kyM1xb0g36ncG1gt7XwYzQdB04t89/1O/w1cDnyilFU=/zl2BFjjKVAWZKz1W0atGTVYNVkpQL9R5kyM1xb0g36ncG1gt7XwYzQdB04t89/1O/w1cDnyilFU=/zl2BFjjKVAVkujU9wTy+zdBddBDrnNdDCGnRkR5pOFThPFEyoIGAggdB04t89/1O/w1cDnyilFU=')
handler = WebhookHandler('cc63231b861c6d4f908cc904d6504fee')

# ngrok
ngrok.set_auth_token("2kSMB4R877gUNnX5eO2VhtLd9qx_7jg36onQ9bnn6YjMgfYdG")

# 斷開任何現有的隧道
tunnels = ngrok.get_tunnels()
for tunnel in tunnels:
    ngrok.disconnect(tunnel.public_url)

# 連接新隧道
public_url = ngrok.connect(5000).public_url
callback_url = f"{public_url}/callback"
print("Callback URL:", callback_url)

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)  # 設置 Flask 應用的隨機秘密金鑰

# 用於儲存使用者狀態的全域字典
user_states = {}

def generate_description(hid):
    try:
        # 使用 Cypher 查詢 Neo4j 資料庫中的房屋資料
        query = f"""
        MATCH (h:House {{hid: '{hid}'}})
        OPTIONAL MATCH (h)-[:NEAR_SUBWAY]->(s:Subway)
        OPTIONAL MATCH (h)-[:NEAR_BUS]->(b:Bus)
        RETURN h, COLLECT(DISTINCT s.name) AS subway_stations, COLLECT(DISTINCT b.name) AS bus_stations
        """
        result = graph.run(query).data()

        # 檢查是否有結果
        if not result or len(result) == 0:
            return "未找到與該HID相關的房屋資料。"

        # 獲取查詢結果中的房屋資料
        house_info = dict(result[0]['h'])
        descriptions = []

        # 填充房屋信息描述
        if house_info.get("adress"):
            descriptions.append(f"房屋地址位於 {house_info['adress']}。")
        if house_info.get("type"):
            descriptions.append(f"該房屋類型為 {house_info['type']}。")
        if house_info.get("pattern"):
            descriptions.append(f"房屋格局為 {house_info['pattern']}。")
        if house_info.get("size"):
            descriptions.append(f"房屋大小為 {house_info['size']} 。")
        if house_info.get("layer"):
            descriptions.append(f"樓層為 {house_info['layer']}。")
        if house_info.get("price"):
            descriptions.append(f"房屋租金為 {house_info['price']} 元。")

        # 填充附近交通信息描述
        subway_stations = result[0]['subway_stations']
        bus_stations = result[0]['bus_stations']
        if subway_stations:
            descriptions.append(f"附近的捷運站有：{', '.join(subway_stations)}。")
        if bus_stations:
            descriptions.append(f"附近的公車站有：{', '.join(bus_stations)}。")

        return "\n".join(descriptions)

    except Exception as e:
        print(f"Error occurred while fetching data for HID {hid}: {e}")
        return "在獲取房屋資料時發生錯誤，請稍後再試。"

def gpt_analyze_input(hid, message):
    try:
        description = generate_description(hid)
        if "未找到與該HID相關的房屋資料" in description:
            return description

        prompt = f"以下是房屋的相關資訊：\n{description}\n\n使用者提問：{message}\n\n請根據房屋資訊和使用者提問提供適當的回覆。"

        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo-16k",
            messages=[
                {"role": "system", "content": "你是一個專業的房屋中介助手，能夠回答租屋相關問題，並幫助查找房屋。如果對於使用者的提問不確定如何回答，請表明自己也不確定並請使用者自行詢問房東。使用者也有可能且用繁體中文回答，盡量簡短回答。"},
                {"role": "user", "content": prompt}
            ]
        )
        return response['choices'][0]['message']['content']
    except Exception as e:
        print(f"Error occurred: {e}")
        return "在處理您的請求時發生錯誤。"

def find_houses_by_criteria(message):
    try:
        # 使用正則表達式提取可能的查詢條件
        subway_pattern = re.search(r'捷運站\s*:\s*([\u4e00-\u9fa5]+)', message)
        bus_pattern = re.search(r'公車站\s*:\s*([\u4e00-\u9fa5]+)', message)
        price_pattern = re.search(r'房租\s*:\s*(\d+)-(\d+)', message)
        address_pattern = re.search(r'地址\s*:\s*([\u4e00-\u9fa5]+)', message)
        type_pattern = re.search(r'類型\s*:\s*([\u4e00-\u9fa5]+)', message)

        subway = subway_pattern.group(1) if subway_pattern else None
        bus = bus_pattern.group(1) if bus_pattern else None
        min_price = int(price_pattern.group(1)) if price_pattern else None
        max_price = int(price_pattern.group(2)) if price_pattern else None
        address = address_pattern.group(1) if address_pattern else None
        type_ = type_pattern.group(1) if type_pattern else None

        # 構建 Neo4j 查詢語句
        query = "MATCH (h:House) WHERE 1=1"
        if subway:
            query += f" AND h.subway CONTAINS '{subway}'"
        if bus:
            query += f" AND h.bus CONTAINS '{bus}'"
        if min_price is not None and max_price is not None:
            query += f" AND h.price >= {min_price} AND h.price <= {max_price}"
        if address:
            query += f" AND h.adress CONTAINS '{address}'"
        if type_:
            query += f" AND h.type CONTAINS '{type_}'"

        # 按租金排序並限制最多5筆資料
        query += " RETURN h.hid AS hid ORDER BY h.price LIMIT 5"

        # 執行查詢
        results = graph.run(query).data()

        # 處理結果
        if results:
            links_list = "\n".join([f"{i+1}. [詳細資料](http://4.227.176.245/house_detail?hid={item['hid']})" for i, item in enumerate(results)])
            return f"根據您的需求，以下房子較符合您的條件：\n{links_list}\n如都無符合您的需求，請使用APP內的搜尋。"
        else:
            return "沒有符合您描述的房子。"

    except Exception as e:
        print(f"Error occurred: {e}")
        return "在處理您的請求時發生錯誤。"

def gpt_renting_knowledge(message):
    try:
        # 使用 ChatGPT 來回答租屋相關知識
        prompt = f"使用者想了解租屋相關知識，以下是問題描述：{message}\n請根據網站 https://prestigeoic.com/10things_mustknow_renting_a_house/ 提供適當的回覆，摘要重點即可。"

        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo-16k",
            messages=[
                {"role": "system", "content": "你是一個專業的房屋租賃顧問，能夠回答與租屋有關的問題，並提供建議。根據參考資料來回答，用繁體中文表達，盡量簡短回答。"},
                {"role": "user", "content": prompt}
            ]
        )
        return response['choices'][0]['message']['content']
    except Exception as e:
        print(f"Error occurred: {e}")
        return "在處理您的請求時發生錯誤。"

# Linebot 回調
@app.route("/callback", methods=['POST'])
def callback():
    signature = request.headers['X-Line-Signature']
    body = request.get_data(as_text=True)
    app.logger.info("Request body: " + body)

    try:
        handler.handle(body, signature)
    except InvalidSignatureError:
        abort(400)

    return 'OK'

@handler.add(MessageEvent, message=TextMessage)
def handle_message(event):
    user_id = event.source.user_id
    user_message = event.message.text.strip()

    # 判斷用戶是否輸入了 "hid: 編號"
    hid_match = re.match(r'hid:\s*(\S+)', user_message)
    if hid_match:
        hid = hid_match.group(1)
        response_message = f"驗證成功，使用者您好，您可以詢問有關 {hid} 物件的任何問題，我會盡可能回復您。\n\n其他功能：智慧搜尋請按1，租屋知識請按2。"
        line_bot_api.reply_message(event.reply_token, TextSendMessage(text=response_message))
        user_states[user_id] = {"hid": hid}
        return

    # 判斷是否為房屋查詢、智慧搜尋、或是租屋知識查詢
    if user_message == "1":
        user_states[user_id] = {"mode": "search"}
        response_message = "請輸入您的搜尋條件，例如：捷運站、房租、地址。\n\n其他功能：租屋知識請按2。"
    elif user_message == "2":
        user_states[user_id] = {"mode": "knowledge"}
        response_message = "請問您想了解什麼樣的租屋知識？例如：租房須知、租房建議等。\n\n其他功能：智慧搜尋請按1。"
    elif user_id in user_states and "hid" in user_states[user_id]:
        # 有輸入 HID 的情況下，使用 GPT 來分析用戶的具體提問
        hid = user_states[user_id]["hid"]
        response_message = gpt_analyze_input(hid, user_message)
        response_message += "\n\n其他功能：\n智慧搜尋請按1，租屋知識請按2。"
    elif user_id in user_states and user_states[user_id].get("mode") == "search":
        # 處理智慧搜尋
        response_message = find_houses_by_criteria(user_message)
        response_message += "\n\n其他功能：租屋知識請按2。"
    elif user_id in user_states and user_states[user_id].get("mode") == "knowledge":
        # 處理租屋知識查詢
        response_message = gpt_renting_knowledge(user_message)
        response_message += "\n\n其他功能：智慧搜尋請按1。"
    else:
        response_message = "請先選擇功能：\n輸入hid查詢房屋，按1進行智慧搜尋，按2查詢租屋知識。"

    # 回應用戶
    line_bot_api.reply_message(event.reply_token, TextSendMessage(text=response_message))

if __name__ == "__main__":
    app.run()