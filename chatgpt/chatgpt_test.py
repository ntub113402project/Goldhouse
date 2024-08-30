#pip install openai==0.28
import openai
from flask import Flask, request, abort, session
from linebot import LineBotApi, WebhookHandler
from linebot.exceptions import InvalidSignatureError
from linebot.models import *
from pyngrok import ngrok
import secrets
import json
import re
from flask_session import Session
from datetime import timedelta
import os

#* 設定 OpenAI API 金鑰
openai.api_key = ""

#* 設定 Line Bot 的 Channel access token 和 Channel secret
line_bot_api = LineBotApi('oohH26PwqEwNLSTT9fQJ9DdqfBXd63TnFNVWb32ZuzL6wLsYJx09guQOh2KUCKEmXUpCKu4dbAu6hA5b4A4JoBS57j202fZ/zl2BFjjKVAVkujU9wTy+zdBddBDrnNdDCGnRkR5pOFThPFEyoIGAggdB04t89/1O/w1cDnyilFU=')
handler = WebhookHandler('3d91af865d2568e735554c9c99b8cb01')

#* 設定 ngrok Key
ngrok.set_auth_token("2kya5GehP9L98hKzPHzI15tUB91_4uX7Vdy9Fk2oDKpq8j7kA")
print("\nPublic URL:" + ngrok.connect(5000).public_url + "\n")

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

#* 配置 Flask-Session 使用文件系統存儲
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_FILE_DIR'] = os.path.join(os.getcwd(), 'flask_session')  # 確保這個目錄存在且有寫入權限
app.config['SESSION_PERMANENT'] = True
app.permanent_session_lifetime = timedelta(minutes=30)
app.config['SESSION_USE_SIGNER'] = False
app.config['SESSION_KEY_PREFIX'] = 'flask_session:'

# 初始化 Session
Session(app)

# #* 設置 Cookie 配置
# app.config['SESSION_COOKIE_SECURE'] = True  # 如果使用 HTTPS，請設為 True
# app.config['SESSION_COOKIE_HTTPONLY'] = True
# app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'

#* 讀取 JSON 檔案
with open('data.json', 'r', encoding='utf-8') as f:
    house_data = json.load(f)

#* GPT 分析資料
def gpt_analyze_input(message):
    try:
        json_str = json.dumps(house_data, ensure_ascii=False, indent=2)
        prompt = f"Here is some JSON data:\n{json_str}\n\nUser message: {message}\n\nBased on the JSON data and user message, please provide an appropriate response."
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "你是一個專業的房屋中介助手，能夠回答租屋相關問題，並幫助查找房屋。"},
                {"role": "user", "content": prompt}
            ]
        )
        return response.choices[0].message["content"]
    except Exception as e:
        print(f"Error occurred: {e}")
        return "An error occurred while processing your request."

#* session detection
def session_detection():
    # 檢查 session 是否存在
    if not session:
        print("Session is empty or not initialized.")
        return

    # 將 session 轉換為字典以便檢測
    session_data = {key: session[key] for key in session}

    # 打印 session 中所有的鍵及其對應的值
    for key, value in session_data.items():
        print(f"Key: {key}, Value: {value}")

    # 根據需要進行額外的處理
    if 'user_valid' in session_data:
        user_valid = session_data['user_valid']
        print(f"user_valid: {user_valid}")
    else:
        print("user_valid not found in session.")

# Linebot
@app.route("/callback", methods=['POST'])
def callback():
    signature = request.headers['X-Line-Signature']
    body = request.get_data(as_text=True)
    app.logger.info("Request body: " + body)

    try:
        handler.handle(body, signature)
    except InvalidSignatureError:
        abort(400)

    # 打印 session 內容以進行調試
    print("Current session:", session)

    return 'OK'

@handler.add(MessageEvent, message=TextMessage)
def handle_message(event):
    user_id = event.source.user_id
    user_message = event.message.text

    if 'user_valid' in session and session.get('user_valid', True):
        hid = session.get('hid')
        response_message = gpt_analyze_input(user_message)
    else:
        # 使用者登入 (需提供hid 和 member_id)
        pattern = re.compile(r'^member_id:(\d+)\s+hid:(\d+)$')
        match = pattern.match(user_message)
        
        if match:
            member_id, hid = match.groups()
            session['user_valid'] = True
            session['member_id'] = member_id
            session['hid'] = hid
            session.permanent = True  # 確保 session 是永久的
            response_message = f"驗證成功，使用者您好，您可以訊問有關 {hid} 這筆物件的任何問題，我會盡可能回覆您。"
        else:
            response_message = "您提供的登入格式有誤, 請重新驗證"

    line_bot_api.reply_message(event.reply_token, TextSendMessage(text=response_message))
    # session_detection()

if __name__ == "__main__":
    app.run()