import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class House {
  final int id;
  final String type;
  final String name; 
  final int size;
  final String city;
  final String district;
  final int price;
  final List<String> imageUrl; 
  bool isFavorite;
  
  House({required this.id, required this.type, required this.name, required this.size, required this.city, required this.district, required this.price, required this.imageUrl, this.isFavorite=true});
}
final List<House> houses = [
    House(
      id: 1,
      imageUrl: ['https://img1.591.com.tw/house/2024/04/27/171421638417334102.jpg!750x588.water2.jpg','https://img1.591.com.tw/house/2024/05/24/171652713612887601.jpg!1000x.water2.jpg','https://img2.591.com.tw/house/2024/05/24/171652713608955407.jpg!1000x.water2.jpg'], 
      type: '獨立套房',
      name: '中正9分獨立門戶',
      size: 8,
      city: '台北市',
      district: '中正區',
      price: 20000,   
    ),
    House(
      id: 2,
      imageUrl: ['https://img1.591.com.tw/house/2022/08/13/166038129846143218.jpg!1000x.water2.jpg'], 
      type: '獨立套房',
      name: '光復橋🌳西園陽台大套房/可寵物/可報稅',
      size: 8,
      city: '台北市',
      district: '萬華區',
      price: 18000,   
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

List<String> allservices = [
    '冰箱',
    '洗衣機',
    '電視',
    '冷氣',
    '熱水器',
    '瓦斯',
    '床',
    '衣櫃',
    '第四台',
    '沙發',
    '桌椅',
    '陽台',
    '電梯',
    '車位',
    '廚房'
  ];

List<String> allservices1 = [
    '冰箱',
    '洗衣機',
    '電視',
    '冷氣',
    '熱水器',
    '床',
    '衣櫃',
    '第四台',
    '網路',
    '天然瓦斯',
    '沙發',
    '桌椅',
    '陽台',
    '電梯',
    '車位',
  ];

final Map<String, IconData> servicesIcons = {
    '冰箱': Icons.kitchen_rounded,
    '洗衣機': Icons.local_laundry_service_rounded,
    '電視': Icons.tv_rounded,
    '冷氣': Icons.ac_unit_rounded,
    '熱水器': Icons.water_damage_rounded,
    '瓦斯': Icons.fireplace_rounded,
    '床': Icons.bed_rounded,
    '衣櫃': Icons.storage,
    '第四台': Icons.cable_rounded,
    '沙發': Icons.weekend_rounded,
    '桌椅': Icons.event_seat_rounded,
    '陽台': Icons.balcony_rounded,
    '電梯': Icons.elevator_rounded,
    '車位': Icons.local_parking_rounded,
    '廚房': Icons.restaurant_menu_rounded
  };

  final Map<String, IconData> servicesIcons1 = {
    '冰箱': Icons.kitchen_rounded,
    '洗衣機': Icons.local_laundry_service_rounded,
    '電視': Icons.tv_rounded,
    '冷氣': Icons.ac_unit_rounded,
    '熱水器': Icons.water_damage_rounded,   
    '床': Icons.bed_rounded,
    '衣櫃': Icons.storage,
    '第四台': Icons.cable_rounded,
    '網路': Icons.network_wifi,
    '天然瓦斯': Icons.fireplace_rounded,
    '沙發': Icons.weekend_rounded,
    '桌椅': Icons.event_seat_rounded,
    '陽台': Icons.balcony_rounded,
    '電梯': Icons.elevator_rounded,
    '車位': Icons.local_parking_rounded,
    
  };
  
class FavoriteManager {
  static final FavoriteManager _instance = FavoriteManager._internal();
  factory FavoriteManager() {
    return _instance;
  }
  FavoriteManager._internal();
  
  Set<String> _favoriteHids = {};

  Future<void> initializeFavorites() async {
    if (_favoriteHids.isEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? memberId = prefs.getInt('member_id');
      if (memberId != null) {
        final response = await http.get(
          Uri.parse('http://4.227.176.245:5000/favorites/$memberId'),
        );

        if (response.statusCode == 200) {
          List<dynamic> favorites = json.decode(response.body);
          _favoriteHids = favorites.map((house) => house['hid'].toString()).toSet();
        }
      }
    }
  }

  Set<String> get favoriteHids => _favoriteHids;
}

// class SubscriptionManager {
//   Future<List<Map<String, dynamic>>> loadSubscriptions() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     int? memberId = prefs.getInt('member_id');

//     if (memberId == null) {
//       print('Member ID not found');
//       return [];
//     }

//     final response = await http.post(
//       Uri.parse('http://4.227.176.245:5000/get_subscriptions'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'member_id': memberId}),
//     );

//     if (response.statusCode == 200) {
//       final List<dynamic> data = jsonDecode(response.body);
//       print('Received data: $data');
//       return data
//           .map((item) => {
//                 'subscription_id': item['subscription_id'],
//                 'city': item['city'],
//                 'district': List<String>.from(item['district']),
//                 'pattern': List<String>.from(item['pattern']),
//                 'rentalrange': item['rentalrange'],
//                 'roomcount': item['roomcount'],
//                 'size': item['size'],
//                 'type': List<String>.from(item['type']),
//                 'properties': [],
//               })
//           .toList();
//     } else {
//       print('Failed to fetch subscriptions');
//       return [];
//     }
//   }

// }
