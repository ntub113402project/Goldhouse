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
from py2neo import Graph
import secrets
import re

# 設定 OpenAI API 金鑰
openai.api_key = ""

# 設定 Neo4j 連接
graph = Graph("bolt://localhost:7687", auth=("neo4j", "12345678"))

# Line Bot API
line_bot_api = LineBotApi('oohH26PwqEwNLSTT9fQJ9DdqfBXd63TnFNVWb32ZuzL6wLsYJx09guQOh2KUCKEmXUpCKu4dbAu6hA5b4A4JoBS57j202fZ/zl2BFjjKVAVkujU9wTy+zdBddBDrnNdDCGnRkR5pOFThPFEyoIGAggdB04t89/1O/w1cDnyilFU=')
handler = WebhookHandler('3d91af865d2568e735554c9c99b8cb01')

# ngrok
ngrok.set_auth_token("2kSMB4R877gUNnX5eO2VhtLd9qx_7jg36onQ9bnn6YjMgfYdG")

# 斷開任何現有的隧道
tunnels = ngrok.get_tunnels()
for tunnel in tunnels:
    ngrok.disconnect(tunnel.public_url)

# 連接新隧道
public_url = ngrok.connect(5000)
print("Public URL:", public_url)

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)  # 設置 Flask 應用的隨機秘密金鑰

# 用於儲存使用者狀態的全域字典
user_states = {}

# 生成房屋描述的函數
def generate_description(hid):
    query = f"""
    MATCH (h:Property {{hid: '{hid}'}})
    OPTIONAL MATCH (h)-[:NEAR_STORE]->(s:Store)
    RETURN h, collect(s) as stores
    """
    result = graph.run(query).data()

    if not result:
        return "未找到與該HID相關的房屋資料。"

    house_info = result[0]['h']
    stores = result[0]['stores']
    
    descriptions = []

    if house_info.get("address"):
        descriptions.append(f"房屋地址位於{house_info['address']}。")
    if house_info.get("type"):
        descriptions.append(f"該房屋類型為{house_info['type']}。")
    if house_info.get("pattern"):
        descriptions.append(f"房屋格局為{house_info['pattern']}。")
    if house_info.get("size"):
        descriptions.append(f"房屋大小為{house_info['size']}坪。")
    if house_info.get("layer"):
        descriptions.append(f"樓層為{house_info['layer']}。")
    if house_info.get("price"):
        descriptions.append(f"房屋租金為{house_info['price']}元。")
    if house_info.get("subway"):
        descriptions.append(f"距離最近的捷運站為{house_info['subway']}。")
    if house_info.get("bus"):
        descriptions.append(f"附近的公車站包括{house_info['bus']}。")

    if stores:
        store_names = [store.get('name') for store in stores if store.get('name')]
        if store_names:
            descriptions.append(f"附近有以下店家：{', '.join(store_names)}。")

    return " ".join(descriptions)

# GPT 分析功能
def gpt_analyze_input(message, user_id):
    try:
        # 專業系統消息
        system_message = (
            "你是一個專業的房屋中介助手，負責回答租屋相關問題，且一律用繁體中文回答。"
            "你的回答應該簡潔、明確，直接解答用戶的問題。"
            "當用戶問到關於房屋的具體細節（例如價格、位置、設施等）時，請根據房屋的主頁資訊進行回答。"
            "如果用戶詢問的問題在房屋的主頁中沒有答案，請建議用戶聯繫房東以獲取更多資訊。"
            "當用戶提問涉及到無法回答的範疇，例如法律建議、詳細合同內容或技術支持時，也請建議他們直接聯繫房東或相關專業人士。"
            "此外，你也可以回答關於租屋相關知識的問題，根據這個網站的信息 'https://www.dd-room.com/article/611e1d8ef0e5483bb5447b3b'。"
            "請確保你的回答專注於租屋相關的信息，並避免提供無關的訊息。"
            "回答時不要提及參考資料來源，也不要說你是根據什麼資料做出回答的。"
            "總之，你的主要目標是幫助用戶解決具體的租屋問題，並在需要時指引他們聯繫房東。"
        )

        # 判斷是否查詢租屋知識或房屋的具體信息
        if "租屋知識" in message or "租屋相關" in message:
            # 如果用戶詢問租屋相關知識
            prompt = (
                f"User message: {message}\n\n"
                "根據這個網站提供的信息『https://www.dd-room.com/article/611e1d8ef0e5483bb5447b3b』，給出準確且專業的回應。"
            )
        else:
            # 如果用戶詢問房屋的具體信息
            hid_match = re.search(r'hid:\s*(\d+)', message)
            if hid_match:
                hid = hid_match.group(1)
                description = generate_description(hid)
                if "未找到與該HID相關的房屋資料" in description:
                    return description
                prompt = (
                    f"以下是房屋的相關資訊：\n{description}\n\n"
                    f"使用者提問：{message}\n\n"
                    "請根據房屋資訊和使用者提問提供適當的回覆。如果數據不足以回答，建議用戶聯繫房東。"
                )
            else:
                # 如果不包含hid，視為租屋知識問題
                prompt = (
                    f"User message: {message}\n\n"
                    "根據這個網站提供的信息『https://www.dd-room.com/article/611e1d8ef0e5483bb5447b3b』，給出準確且專業的回應。"
                )

        # 調用 OpenAI API 生成回應
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user", "content": prompt}
            ]
        )

        reply_content = response['choices'][0]['message']['content']

        # 添加「根據您所要搜尋的房屋資訊」到回應開頭（僅當查詢房屋信息時）
        if "hid:" in message:
            reply_content = "根據您所要搜尋的房屋資訊，" + reply_content

        return reply_content

    except Exception as e:
        print(f"Error occurred: {e}")  # 打印錯誤信息
        return "在處理您的請求時發生錯誤。"

# 智慧搜尋功能
def find_houses_by_criteria(message):
    try:
        # 使用正則表達式提取可能的查詢條件
        subway_pattern = re.search(r'捷運站\s*:\s*([\u4e00-\u9fa5]+)', message)
        bus_pattern = re.search(r'公車站\s*:\s*([\u4e00-\u9fa5]+)', message)
        price_pattern = re.search(r'房租\s*:\s*(\d+)-(\d+)', message)
        size_pattern = re.search(r'坪數\s*:\s*(\d+)-(\d+)', message)
        address_pattern = re.search(r'地址\s*:\s*([\u4e00-\u9fa5]+)', message)
        layer_pattern = re.search(r'樓層\s*:\s*(\d+)', message)
        pattern_pattern = re.search(r'格局\s*:\s*([\u4e00-\u9fa5]+)', message)
        type_pattern = re.search(r'類型\s*:\s*([\u4e00-\u9fa5]+)', message)

        subway = subway_pattern.group(1) if subway_pattern else None
        bus = bus_pattern.group(1) if bus_pattern else None
        min_price = int(price_pattern.group(1)) if price_pattern else None
        max_price = int(price_pattern.group(2)) if price_pattern else None
        min_size = int(size_pattern.group(1)) if size_pattern else None
        max_size = int(size_pattern.group(2)) if size_pattern else None
        address = address_pattern.group(1) if address_pattern else None
        layer = int(layer_pattern.group(1)) if layer_pattern else None
        pattern = pattern_pattern.group(1) if pattern_pattern else None
        type_ = type_pattern.group(1) if type_pattern else None

        # 構建 Neo4j 查詢語句
        query = "MATCH (h:Property) WHERE 1=1"
        if subway:
            query += f" AND h.subway CONTAINS '{subway}'"
        if bus:
            query += f" AND h.bus CONTAINS '{bus}'"
        if min_price is not None and max_price is not None:
            query += f" AND h.price >= {min_price} AND h.price <= {max_price}"
        if min_size is not None and max_size is not None:
            query += f" AND h.size >= {min_size} AND h.size <= {max_size}"
        if address:
            query += f" AND h.address CONTAINS '{address}'"
        if layer:
            query += f" AND h.layer = {layer}"
        if pattern:
            query += f" AND h.pattern CONTAINS '{pattern}'"
        if type_:
            query += f" AND h.type CONTAINS '{type_}'"

        query += " RETURN h.hid AS hid, h.subway AS subway, h.bus AS bus"

        # 執行查詢
        results = graph.run(query).data()

        def extract_distance(text):
            """從字串中提取數字，如果沒有數字則返回無窮大"""
            if text:
                match = re.search(r'(\d+)', text)
                if match:
                    return int(match.group(1))
            return float('inf')

        # 處理並排序結果
        house_distances = []
        for result in results:
            subway_distance = extract_distance(result['subway'])
            bus_distance = extract_distance(result['bus'])
            total_distance = subway_distance + bus_distance
            house_distances.append((result['hid'], total_distance))

        # 按距離排序並選擇最小的十個結果
        house_distances.sort(key=lambda x: x[1])
        top_houses = house_distances[:10]

        if top_houses:
            hids_list = "\n".join([f"{i+1}. 編號 {hid}" for i, (hid, _) in enumerate(top_houses)])
            return f"根據您的需求，以下房子較符合您的條件：\n{hids_list}如都無符合您的需求，請使用APP內的搜尋"
        else:
            return "沒有符合您描述的房子。"

    except Exception as e:
        print(f"Error occurred: {e}")  # 打印錯誤信息
        return "在處理您的請求時發生錯誤。"


# Linebot 回調
@app.route("/callback", methods=['POST'])
def callback():
    signature = request.headers['X-Line-Signature']  # 獲取 Line 請求簽名
    body = request.get_data(as_text=True)  # 以文本形式獲取請求體
    app.logger.info("Request body: " + body)

    try:
        handler.handle(body, signature)  # 使用 Line WebhookHandler 處理請求
    except InvalidSignatureError:
        abort(400)  # 簽名無效時返回 400 錯誤

    return 'OK'

@handler.add(MessageEvent, message=TextMessage)
def handle_message(event):
    user_id = event.source.user_id  # 獲取用戶 ID
    user_message = event.message.text  # 獲取用戶消息

    print("Received message:", user_message)  # 打印接收到的消息

    # 清理用戶狀態或結果，避免前一條訊息的影響
    user_states[user_id] = {
        'user_valid': False,
        'hid': None,
        'messages': []
    }

    if "hid:" in user_message:
        # 回答房屋問題
        response_message = gpt_analyze_input(user_message, user_id)
    elif "租屋" in user_message or "租房" in user_message:
        # 回答租屋知識問題
        response_message = gpt_analyze_input(user_message, user_id)
    else:
        # 處理查詢特定條件的房屋問題
        response_message = find_houses_by_criteria(user_message)

    # 調試：打印當前用戶狀態
    print(f"User states after processing: {user_states}")

    line_bot_api.reply_message(event.reply_token, TextSendMessage(text=response_message))  # 回覆用戶消息


if __name__ == "__main__":
    app.run()  # 運行 Flask 應用
