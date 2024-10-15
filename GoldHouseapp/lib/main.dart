import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';
import 'pages/forgetpw_page.dart';
import 'pages/search_page.dart';
import 'pages/personal_page.dart';
import 'pages/controll_page.dart';
import 'pages/housedetail_page.dart';
import 'pages/class.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoriteManager().initializeFavorites();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
        '/forgetpw': (context) => const ForgetpwPage(),
        '/search': (context) => const SearchPage(),
        '/personal': (context) => const PersonalPage(),
        '/controll': (context) => const ControllPage(),
      },
      home: const AppLinksHandler(), 
    );
  }
}

class AppLinksHandler extends StatefulWidget {
  const AppLinksHandler({super.key});

  @override
  State<AppLinksHandler> createState() => _AppLinksHandlerState();
}

class _AppLinksHandlerState extends State<AppLinksHandler> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initDeepLinkListener();
  }

  void _initDeepLinkListener() async {
    // 監聽啟動應用時的連結
    Uri? initialLink = await _appLinks.getInitialLink();
    if (initialLink != null) {
      _handleDeepLink(initialLink);
    }

    // 監聽在應用啟動後點擊的連結
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
  if (uri.path == '/house_detail' && uri.queryParameters.containsKey('hid')) {
    String hid = uri.queryParameters['hid']!;

    // 根據 hid 從後端 API 獲取房屋資料
    final response = await http.get(Uri.parse('http://4.227.176.245:5000/houses/$hid'));

    if (response.statusCode == 200) {
      Map<String, dynamic> houseDetails = jsonDecode(response.body);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HouseDetailPage(houseDetails: houseDetails),
        ),
      );
    } else {
      ('Failed to load house details: ${response.statusCode}');
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return const ControllPage();
  }
}