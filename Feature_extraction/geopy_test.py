from geopy.geocoders import Nominatim
import sys
sys.stdout.reconfigure(encoding='utf-8')
# 使用不同的 User-Agent 初始化地理编码器
geolocator = Nominatim(user_agent="myGeocoder")

# 定义地址
address = "中山區林森北路"

# 获取经纬度
location = geolocator.geocode(address)

# 打印结果
if location:
    print(f"Address: {address}")
    print(f"Latitude: {location.latitude}")
    print(f"Longitude: {location.longitude}")
else:
    print("地址无法找到经纬度。")