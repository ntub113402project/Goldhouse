from flask import Flask, request, abort
from linebot import LineBotApi, WebhookHandler
from linebot.exceptions import InvalidSignatureError
from linebot.models import MessageEvent, TextMessage, TextSendMessage
from ckiptagger import WS
from pyngrok import ngrok
import openai
import json

openai.api_key =  
def chatgpt_QA(Q):
    prompt = f"用繁體中文回復: {Q}"
    response = openai.Completion.create(
        model="text-davinci-003",
        prompt=prompt,
        temperature=0,
        max_tokens=500,
        top_p=1,
        frequency_penalty=0.5,
        presence_penalty=0
    )
    return response["choices"][0]["text"].strip()

ws = WS("D:/ckiptagger-master/data")

ngrok.set_auth_token("2eDgAPZdUij5iLuoH2XoMeyymJW_3jiPDYDctRTF96kWVptpk")
print("\nPublic URL:" + ngrok.connect(5000).public_url + "\n")

line_bot_api = LineBotApi('OQD5Y8I0VeQ+/6FUuD7B80kNJ7r623LrYP828AnEutWgDoFML5QxD6s/EeYMJAwaXUpCKu4dbAu6hA5b4A4JoBS57j202fZ/zl2BFjjKVAXCNocELJAwpm8Exka0xJ0CmXYS1mlXCcfs2nJm18f0MgdB04t89/1O/w1cDnyilFU=')
handler = WebhookHandler('3d91af865d2568e735554c9c99b8cb01')

app = Flask(__name__)

with open('data.json', 'r', encoding='utf-8') as f:
    detail_data = json.load(f)

def chatgpt_QA(Q):
    if Q in detail_data:
        reference_info = detail_data[Q]
        prompt = f"參考以下資料回答問題：{reference_info}\n問題：{Q}"
    else:
        return "無參考資料無法回答"

    response = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "以下對話請用繁體中文回答問題"},
            {"role": "user", "content": prompt}
        ]
    )
    return response["choices"][0]['message']["content"].strip()

@app.route("/test", methods=['GET'])
def test():
    return 'test'

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
    user_message = event.message.text
    
    ckiplist = ws([user_message])
    segmented_text = " ".join(ckiplist[0])
    
    response_message = chatgpt_QA(segmented_text)
    
    print(response_message)
    line_bot_api.reply_message(event.reply_token, TextSendMessage(response_message))

if __name__ == "__main__":
    app.run()