from flask import Flask
from flask import request, abort
from linebot import  LineBotApi, WebhookHandler
from linebot.exceptions import InvalidSignatureError
from linebot.models import *
from pyngrok import ngrok
import json
from openai import OpenAI
from ckiptagger import WS

#todo openai key
client = OpenAI(api_key=)

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

ws = WS("D:/ckiptagger-master/data") #你的ckiptagger ws的位置

#todo ngrok Key
ngrok.set_auth_token("2eDgAPZdUij5iLuoH2XoMeyymJW_3jiPDYDctRTF96kWVptpk")
print("\nPublic URL:" + ngrok.connect(5000).public_url +"\n")

#todo Channel access token
line_bot_api = LineBotApi('OQD5Y8I0VeQ+/6FUuD7B80kNJ7r623LrYP828AnEutWgDoFML5QxD6s/EeYMJAwaXUpCKu4dbAu6hA5b4A4JoBS57j202fZ/zl2BFjjKVAXCNocELJAwpm8Exka0xJ0CmXYS1mlXCcfs2nJm18f0MgdB04t89/1O/w1cDnyilFU=')
#todo Channel secret
handler = WebhookHandler('3d91af865d2568e735554c9c99b8cb01')

#json檔路徑
with open('data.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

app = Flask(__name__)

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
    text1=[event.message.text]
    return_test = ""
    temp=text1[0]
    if "Q:" in temp[:2]:
      Q=temp[2:]
      return_test=chatgpt_QA(Q)
    else:
      ckiplist = ws(text1)
      for tag in ckiplist:
        return_test += str(tag) + ","
    print(return_test)
    line_bot_api.reply_message(event.reply_token,TextSendMessage(return_test))

if __name__ == "__main__":
    app.run()