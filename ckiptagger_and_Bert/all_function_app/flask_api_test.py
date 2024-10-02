@app.route('/add_house', methods=['POST'])
def add_house():
    try:
        data = request.form
        images = request.files.getlist('images')
        member_id = data.get('member_id')

        if not member_id:
            return jsonify({"error": "缺少 member_id"}), 400

        hid = str(uuid.uuid4().int)[:8]
        size = f"{data['size']}坪"

        # 处理房屋设备信息
        refrigerator = 1 if '冰箱' in data['service'] else 0
        washing_machine = 1 if '洗衣機' in data['service'] else 0
        television = 1 if '電視' in data['service'] else 0       
        air_conditioner = 1 if '冷氣' in data['service'] else 0
        water_heater = 1 if '熱水器' in data['service'] else 0
        bed = 1 if '床' in data['service'] else 0
        wardrobe = 1 if '衣櫃' in data['service'] else 0
        cable_tv = 1 if '第四台' in data['service'] else 0
        internet = 1 if '網路' in data['service'] else 0
        natural_gas = 1 if '天然瓦斯' in data['service'] else 0
        sofa = 1 if '沙發' in data['service'] else 0
        table_chair = 1 if '桌椅' in data['service'] else 0
        balcony = 1 if '陽台' in data['service'] else 0
        elevator = 1 if '電梯' in data['service'] else 0
        parking_space = 1 if '車位' in data['service'] else 0

        # 保存房屋图片
        upload_folder = os.path.join(app.config['UPLOAD_FOLDER'], hid)
        if not os.path.exists(upload_folder):
            os.makedirs(upload_folder)

        image_paths = []
        for index, image in enumerate(images):
            filename = f"image{index + 1}.jpg"
            image_path = os.path.join(upload_folder, filename)
            image.save(image_path)
            image_paths.append(f"/houses/{hid}/{filename}")

        # 插入房屋数据
        with db_gh_members.cursor() as cursor:
            sql_house = """
                INSERT INTO new_housedetail (
                    hid, title, pattern, size, layer, deposit, price, 
                    city, district, address, agency, member_id, phone, content
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql_house, (
                hid, data['title'], data['pattern'], size, data['layer'], data['deposit'],
                data['price'], data['city'], data['district'], data['address'],
                data['agency'], member_id, data['phone'], data['content']
            ))

            # 保存服务信息
            sql_service = """
                INSERT INTO new_service (
                    hid, refrigerator, washing_machine, television, air_conditioner, water_heater, bed, wardrobe,
                    cable_tv, internet, natural_gas, sofa, table_chair, balcony, elevator, parking_space
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql_service, (
                hid, refrigerator, washing_machine, television, air_conditioner, water_heater, bed, wardrobe,
                cable_tv, internet, natural_gas, sofa, table_chair, balcony, elevator, parking_space
            ))

            # 保存图片信息
            for image_path in image_paths:
                sql_image = """
                    INSERT INTO house_images (hid, image_path)
                    VALUES (%s, %s)
                """
                cursor.execute(sql_image, (hid, image_path))

            db_gh_members.commit()

        # 调用 Jupyter API 提取文本和图片特征
        try:
            text_features_api_url = "http://127.0.0.1:5001/process_text"
            text_payload = {
                "hid": hid,
                "item": {
                    "address": data['address'],
                    "subway": data.get('subway', '').split(','),
                    "bus": data.get('bus', '').split(','),
                    "pattern": data['pattern'],
                    "size": size,
                    "device": [device for device in data.get('service', '').split(',') if device and data.get('avaliable', True)]
                }
            }
            text_response = requests.post(text_features_api_url, json=text_payload)

            if text_response.status_code != 200:
                raise Exception(f"文字特徵提取失敗: {text_response.status_code}, {text_response.text}")

            # 图片特征提取
            image_features_api_url = "http://127.0.0.1:5001/process_image"
            image_payload = {
                "hid": hid,
                "image_folder": app.config['UPLOAD_FOLDER']
            }
            image_response = requests.post(image_features_api_url, json=image_payload)

            if image_response.status_code != 200:
                raise Exception(f"圖片特徵提取失敗: {image_response.status_code}, {image_response.text}")

        except Exception as e:
            app.logger.error("Error occurred while extracting features: %s", str(e))
            return jsonify({"error": str(e)}), 400

        # 比较房屋特征
        try:
            compare_features_api_url = "http://127.0.0.1:5001/compare_text_features"
            for existing_hid in get_existing_house_ids():
                compare_payload = {
                    "hid1": hid,
                    "hid2": existing_hid
                }
                compare_response = requests.post(compare_features_api_url, json=compare_payload)

                if compare_response.status_code == 200 and compare_response.json().get("similar"):
                    # 如果找到相似房屋，更新 same 值
                    with db_gh_members.cursor() as cursor:
                        cursor.execute("""
                            UPDATE new_housedetail SET same = %s WHERE hid = %s
                        """, (existing_hid, hid))
                        db_gh_members.commit()
                    break

        except Exception as e:
            app.logger.error("Error occurred while comparing features: %s", str(e))
            return jsonify({"error": str(e)}), 400

        return jsonify({"message": "House added successfully", "hid": hid, "images": image_paths}), 200
    except Exception as e:
        app.logger.error("Error occurred: %s", str(e))
        return jsonify({"error": str(e)}), 400

# 获取现有房屋的 hid 列表
def get_existing_house_ids():
    cursor = db_gh_members.cursor()
    cursor.execute("SELECT hid FROM new_housedetail")
    rows = cursor.fetchall()
    cursor.close()
    return [row[0] for row in rows]
