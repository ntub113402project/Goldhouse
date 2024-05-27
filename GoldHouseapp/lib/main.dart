import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/housedetail_page.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';
import 'pages/forgetpw_page.dart';
import 'pages/search_page.dart';
import 'pages/personal_page.dart';
import 'pages/controll_page.dart';
void main() {
  runApp(
    MaterialApp(  
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/register':(context) => RegisterPage(),
        '/login':(context) => LoginPage(),
        '/forgetpw':(context) => ForgetpwPage(),
        '/search':(context) => SearchPage(),
        '/personal':(context) => PersonalPage(),
        '/housedetail':(context) => HouseDetailPage(),
        '/controll':(context) => ControllPage(),
      },
      home: ControllPage(),
    )
  );
}
