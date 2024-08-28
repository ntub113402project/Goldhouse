#pip install openai==0.28
#pip install line-bot-sdk
#pip install pyngrok
#pip install Flask-Session
from pyngrok import ngrok
import openai
from flask import Flask, request, abort
from linebot import LineBotApi, WebhookHandler
from linebot.exceptions import InvalidSignatureError
from linebot.models import TextSendMessage, MessageEvent, TextMessage
import secrets
import json
import re

# 設定 OpenAI API 金鑰
openai.api_key = "" 

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

# 讀取 JSON 資料
with open("C:\\Users\\user\\OneDrive\\桌面\\data.json", 'r', encoding='utf-8') as f:
    house_data = json.load(f)  # 從指定路徑讀取 JSON 文件，並將其解析為字典

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
            json_str = json.dumps(house_data, ensure_ascii=False, indent=2)
            prompt = (
                f"Based on the provided JSON data:\n{json_str}\n\n"
                f"User message: {message}\n\n"
                "根據用戶的問題和提供的數據，給出準確且專業的回應。如果數據不足以回答，建議用戶聯繫房東。"
            )

        # 調用 OpenAI API 生成回應
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user", "content": prompt}
            ]
        )

        return response.choices[0].message["content"]

    except Exception as e:
        print(f"Error occurred: {e}")  # 打印錯誤信息
        return "An error occurred while processing your request."

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

    # 檢查消息是否為正確的登錄格式
    pattern = re.compile(r'^member_id:\s*(\d+)\s+hid:\s*(\d+)$')
    match = pattern.match(user_message)

    if match:
        member_id, hid = match.groups()  # 提取匹配的 member_id 和 hid
        # 更新用戶狀態，重置對話
        user_states[user_id] = {
            'user_valid': True,
            'member_id': member_id,
            'hid': hid,
            'messages': []  # 重置對話信息
        }
        response_message = f"驗證成功，使用者您好，您可以訊問有關 {hid} 這筆物件的任何問題，我會盡可能回覆您。"
    else:
        # 檢查用戶狀態
        if user_id in user_states and user_states[user_id]['user_valid']:
            # 如果用戶已驗證，處理他們的問題
            response_message = gpt_analyze_input(user_message, user_id)
        else:
            response_message = "您提供的登入格式有誤, 請重新驗證"

    # 調試：打印當前用戶狀態
    print(f"User states after processing: {user_states}")

    line_bot_api.reply_message(event.reply_token, TextSendMessage(text=response_message))  # 回覆用戶消息

if __name__ == "__main__":
    app.run()  # 運行 Flask 應用
