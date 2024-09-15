import 'package:flutter/material.dart';
import 'pages/class.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';
import 'pages/forgetpw_page.dart';
import 'pages/search_page.dart';
import 'pages/personal_page.dart';
import 'pages/controll_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoriteManager().initializeFavorites();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(),
        '/forgetpw': (context) => ForgetpwPage(),
        '/search': (context) => SearchPage(),
        '/personal': (context) => PersonalPage(),
        '/controll': (context) => ControllPage(),
      },
      home: ControllPage(),
    );
  }
}