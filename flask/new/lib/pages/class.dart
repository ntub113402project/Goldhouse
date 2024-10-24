class House {
  final int id;
  final String type;
  final String name; 
  final int size;
  final String city;
  final String district;
  final int price;
  final List<String> imageUrl; 
  
  House({required this.id, required this.type, required this.name, required this.size, required this.city, required this.district, required this.price, required this.imageUrl});
}
final List<House> houses = [
    House(
      id: 1,
      imageUrl: ['https://img1.591.com.tw/house/2024/04/27/171421638417334102.jpg!750x588.water2.jpg','https://img1.591.com.tw/house/2024/05/24/171652713612887601.jpg!1000x.water2.jpg','https://img2.591.com.tw/house/2024/05/24/171652713608955407.jpg!1000x.water2.jpg'], 
      type: '獨立套房',
      name: '中山站9分獨立門戶',
      size: 8,
      city: '台北市',
      district: '中山區',
      price: 20000,
    ),
    House(
      id: 2,
      imageUrl: ['https://img1.591.com.tw/house/2024/04/27/171421638417334102.jpg!750x588.water2.jpg','https://img1.591.com.tw/house/2024/05/24/171652713612887601.jpg!1000x.water2.jpg'], 
      type: '獨立套房',
      name: '中山站9分獨立門戶',
      size: 8,
      city: '台北市',
      district: '中山區',
      price: 20000,
    ),
  ];

  final List<String> imgList = [
    'https://img2.591.com.tw/house/2024/04/23/171387537620792403.jpg!fit.1000x.water2.jpg',
    'https://img2.591.com.tw/house/2024/04/23/171387537620614704.jpg!fit.1000x.water2.jpg',
    'https://img1.591.com.tw/house/2024/04/23/171387537620549103.jpg!fit.1000x.water2.jpg',
    'https://img2.591.com.tw/house/2024/04/23/171387537624561705.jpg!fit.1000x.water2.jpg',
    'https://img2.591.com.tw/house/2024/04/23/171387537637450408.jpg!fit.1000x.water2.jpg'
  ];


final Map<String, bool> furnitureMap = {
    '沙發': true,
    '冷氣': false,
    '電視 ': true,
    '陽台': false,
    '冰箱': true,
    '電熱水器': false,
    '桌子': true,
    '衣櫃': true,
    '床頭櫃': false,
    '椅子': true,
  };

class HouseDetail {
  final String hid;
  final String url;
  final String title;
  final String pattern;
  final String size;
  final String layer;
  final String type;
  final int price;
  final String deposit;
  final String address;
  final String subway;
  final String bus;

  HouseDetail({
    required this.hid,
    required this.url,
    required this.title,
    required this.pattern,
    required this.size,
    required this.layer,
    required this.type,
    required this.price,
    required this.deposit,
    required this.address,
    required this.subway,
    required this.bus,
  });

}    

    