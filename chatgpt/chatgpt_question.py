#pip install openai==0.28
import openai
from py2neo import Graph


openai.api_key = "openai的key"


graph = Graph("bolt://localhost:7687", auth=("neo4j", "12345678"))

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

def gpt_analyze_input(hid, message):
    try:
        description = generate_description(hid)
        if "未找到與該HID相關的房屋資料" in description:
            return description

        prompt = f"以下是房屋的相關資訊：\n{description}\n\n使用者提問：{message}\n\n請根據房屋資訊和使用者提問提供適當的回覆。"

        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo-16k",
            messages=[
                {"role": "system", "content": "你是一個專業的房屋中介助手，能夠回答租屋相關問題，並幫助查找房屋。如果對於使用者的提問不確定如何回答，請表明自己也不確定並要求使用者自行詢問房東。且用繁體中文回答。"},
                {"role": "user", "content": prompt}
            ]
        )
        return response['choices'][0]['message']['content']
    except Exception as e:
        print(f"Error occurred: {e}")
        return "在處理您的請求時發生錯誤。"

if __name__ == "__main__":
    hid = input("輸入HID：")
    question = input("您的提問：")
    print(f"您查詢的房屋物件為 {hid}\n您提問的問題是 {question}")
    answer = gpt_analyze_input(hid, question)
    if answer:
        print(f"{answer}")
    else:
        print("沒有收到回答，發生錯誤。")