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
from linebot.models import QuickReply, QuickReplyButton, MessageAction

# 設定 OpenAI API 金鑰
openai.api_key = ""

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
        print(f"Trying to fetch data for HID: {hid}")
        # 使用 Cypher 查詢 Neo4j 資料庫中的房屋資料
        query = f"""
        MATCH (h:House {{hid: '{hid}'}})
        OPTIONAL MATCH (h)-[:NEAR_SUBWAY]->(s:Subway)
        OPTIONAL MATCH (h)-[:NEAR_BUS]->(b:Bus)
        OPTIONAL MATCH (h)-[:HAS_DEVICE]->(d:Device)
        OPTIONAL MATCH (h)-[:NEAR_STORE]->(st:Store)
        RETURN h, 
               COLLECT(DISTINCT s.name) AS subway_stations, 
               COLLECT(DISTINCT b.name) AS bus_stations, 
               COLLECT(DISTINCT d.name) AS devices, 
               COLLECT(DISTINCT st.name) AS nearby_stores
        """
        result = graph.run(query).data()

        # 檢查是否有結果
        if not result or len(result) == 0 or not result[0]['h']:
            return "未找到與該HID相關的房屋資料1。"

        # 獲取查詢結果中的房屋資料
        house_info = dict(result[0]['h'])
        descriptions = []

        # 將屬性與對應描述文字對應起來進行統一處理
        fields_to_description = {
            "adress": "房屋地址位於 {value}。",
            "type": "該房屋類型為 {value}。",
            "pattern": "房屋格局為 {value}。",
            "size": "房屋大小為 {value}。",
            "layer": "樓層/最高樓層為 {value}。",
            "price": "房屋租金為 {value} 元。"
        }

        for field, template in fields_to_description.items():
            if house_info.get(field):
                descriptions.append(template.format(value=house_info[field]))

        # 附加設備描述
        devices = result[0]['devices']
        if devices:
            descriptions.append(f"提供的附加設備有：{', '.join(devices)}。")

        # 填充附近交通信息描述
        subway_stations = result[0]['subway_stations']
        bus_stations = result[0]['bus_stations']
        if subway_stations:
            descriptions.append(f"附近的捷運站有：{', '.join(subway_stations)}。")
        if bus_stations:
            descriptions.append(f"附近的公車站有：{', '.join(bus_stations)}。")

        # 周邊店家描述
        nearby_stores = result[0]['nearby_stores']
        if nearby_stores:
            descriptions.append(f"附近的店家有：{', '.join(nearby_stores)}。")

        return "\n".join(descriptions)

    except Exception as e:
        print(f"Error occurred while fetching data for HID {hid}: {e}")
        return "在獲取房屋資料時發生錯誤，請稍後再試。"



def gpt_analyze_input(hid, message):
    try:
        # 確保 hid 被正確傳遞並調用 generate_description
        description = generate_description(hid)
        
        # 如果找不到房屋資料，直接回傳提示
        if "未找到與該HID相關的房屋資料" in description:
            return description

        # OpenAI 提問的 prompt 包含房屋描述，並且請求精簡回答
        prompt = f"以下是房屋的相關資訊：\n{description}\n\n使用者提問：{message}\n\n請用30字內回答問題，根據房屋資訊和使用者提問提供適當的回覆。"

        # 使用 OpenAI 來生成回應
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo-16k",
            messages=[
                {"role": "system", "content": "你是一個專業的房屋中介助手，能夠回答租屋相關問題，並幫助查找房屋。如果對於使用者的提問不確定如何回答，請表明自己也不確定並請使用者自行詢問房東。使用者也有可能且用繁體中文回答，盡量簡短回答。"},
                {"role": "user", "content": prompt}
            ]
        )
        # 返回 OpenAI 生成的回應
        return response['choices'][0]['message']['content']
    except Exception as e:
        print(f"Error occurred: {e}")
        return "在處理您的請求時發生錯誤。"
def find_houses_by_criteria(message):
    try:
        # 使用正則表達式提取可能的查詢條件
        patterns = {
            'subway': re.search(r'捷運站\s*:\s*([\u4e00-\u9fa5]+)', message),
            'bus': re.search(r'公車站\s*:\s*([\u4e00-\u9fa5]+)', message),
            'price': re.search(r'房租\s*:\s*(\d+)-(\d+)', message),
            'pattern': re.search(r'房屋格局\s*:\s*(\d+)', message),
            'address': re.search(r'地址\s*:\s*([\u4e00-\u9fa5]+)', message),
            'type': re.search(r'類型\s*:\s*([\u4e00-\u9fa5]+)', message),
            'size': re.search(r'大小\s*:\s*(\d+)', message),
            'layer': re.search(r'樓層/最高樓層\s*:\s*([\u4e00-\u9fa5]+)', message),
            'device': re.search(r'附加設備有\s*:\s*([\u4e00-\u9fa5]+)', message),
            'store': re.search(r'店家\s*:\s*([\u4e00-\u9fa5]+)', message)
        }

        # 提取匹配值
        subway = patterns['subway'].group(1) if patterns['subway'] else None
        bus = patterns['bus'].group(1) if patterns['bus'] else None
        min_price = int(patterns['price'].group(1)) if patterns['price'] else None
        max_price = int(patterns['price'].group(2)) if patterns['price'] else None
        address = patterns['address'].group(1) if patterns['address'] else None
        pattern = patterns['pattern'].group(1) if patterns['pattern'] else None
        type_ = patterns['type'].group(1) if patterns['type'] else None
        size = patterns['size'].group(1) if patterns['size'] else None
        layer = patterns['layer'].group(1) if patterns['layer'] else None
        device = patterns['device'].group(1) if patterns['device'] else None
        store = patterns['store'].group(1) if patterns['store'] else None

        # 構建 Neo4j 查詢語句
        query = "MATCH (h:House) WHERE 1=1"
        # 處理交通查詢條件
        if subway:
            query += f" AND EXISTS ((h)-[:NEAR_SUBWAY]->(:Subway {{name: '{subway}'}}))"
        if bus:
            query += f" AND EXISTS ((h)-[:NEAR_BUS]->(:Bus {{name: '{bus}'}}))"
        # 處理房租範圍
        if min_price is not None and max_price is not None:
            query += f" AND h.price >= {min_price} AND h.price <= {max_price}"
        # 處理其他查詢條件
        if address:
            query += f" AND h.adress CONTAINS '{address}'"
        if type_:
            query += f" AND h.type CONTAINS '{type_}'"
        if pattern:
            query += f" AND h.pattern CONTAINS '{pattern}'"
        if size:
            query += f" AND h.size = {size}"
        if layer:
            query += f" AND h.layer = {layer}"
        if device:
            query += f" AND EXISTS ((h)-[:HAS_DEVICE]->(:Device {{name: '{device}'}}))"
        if store:
            query += f" AND EXISTS ((h)-[:NEAR_STORE]->(:Store {{name: '{store}'}}))"

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

    # QuickReply buttons, will always appear regardless of functionality
    quick_reply_items = [
        QuickReplyButton(action=MessageAction(label="智慧搜尋", text="智慧搜尋")),
        QuickReplyButton(action=MessageAction(label="租屋小知識", text="租屋小知識")),
        QuickReplyButton(action=MessageAction(label="房屋資訊問答", text="房屋資訊問答"))
    ]
    quick_reply = QuickReply(items=quick_reply_items)

    # 初始化使用者狀態，如果不存在則創建
    if user_id not in user_states:
        user_states[user_id] = {"mode": None, "hid": None}

    # 檢查訊息是否為 "hid: 編號" 格式
    hid_match = re.match(r'hid:\s*(\S+)', user_message)
    if hid_match:
        hid = hid_match.group(1)  # 提取編號
        user_states[user_id]["hid"] = hid  # 儲存 HID
        description = generate_description(hid)
        
        # 如果找到房屋資訊，回傳確認訊息並保持房屋資訊功能狀態
        if "未找到與該HID相關的房屋資料" not in description:
            user_states[user_id]["mode"] = "house_info"  # 設定狀態為房屋資訊
            response_message = TextSendMessage(
                text=f"驗證房屋成功，使用者您好，您可以詢問有關 {hid} 物件的任何問題，我會盡可能回復您。",
                quick_reply=quick_reply  # 顯示 QuickReply 按鈕
            )
        else:
            # 沒有找到房屋，回傳錯誤訊息
            response_message = TextSendMessage(
                text="未找到與該HID相關的房屋資料，請重新輸入。",
                quick_reply=quick_reply  # 顯示 QuickReply 按鈕
            )
    else:
        # 根據使用者當前狀態自動處理訊息
        if user_states[user_id]["mode"] == "house_info" and user_states[user_id]["hid"]:
            response_message = TextSendMessage(
                text=gpt_analyze_input(user_states[user_id]["hid"], user_message),
                quick_reply=quick_reply  # 顯示 QuickReply 按鈕
            )
        elif user_states[user_id]["mode"] == "search":
            response_message = TextSendMessage(
                text=find_houses_by_criteria(user_message),
                quick_reply=quick_reply  # 顯示 QuickReply 按鈕
            )
        elif user_states[user_id]["mode"] == "knowledge":
            response_message = TextSendMessage(
                text=gpt_renting_knowledge(user_message),
                quick_reply=quick_reply  # 顯示 QuickReply 按鈕
            )
        else:
            # 如果沒有設定模式，使用者需要選擇模式
            response_message = TextSendMessage(
                text="請選擇功能：智慧搜尋、租屋小知識、房屋資訊問答",
                quick_reply=quick_reply
            )

    # 如果使用者選擇按鈕，則切換模式
    if user_message == '智慧搜尋':
        user_states[user_id]["mode"] = "search"
        response_message = TextSendMessage(
            text="請輸入您的搜尋條件，例如：捷運站、房租、地址。",
            quick_reply=quick_reply
        )
    elif user_message == '租屋小知識':
        user_states[user_id]["mode"] = "knowledge"
        response_message = TextSendMessage(
            text="請問您想了解什麼樣的租屋知識？例如：租房須知、租房建議等。",
            quick_reply=quick_reply
        )
    elif user_message == '房屋資訊問答':
        user_states[user_id]["mode"] = "house_info"
        response_message = TextSendMessage(
            text="請從APP尋找想了解的房子，再點擊智能助手喔。",
            quick_reply=quick_reply
        )

    # 回覆訊息
    try:
        line_bot_api.reply_message(event.reply_token, response_message)
    except Exception as e:
        print(f"Error occurred: {e}")


if __name__ == "__main__":
    app.run()