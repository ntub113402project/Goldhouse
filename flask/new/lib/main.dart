import 'package:flutter/material.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';
import 'pages/forgetpw_page.dart';
import 'pages/search_page.dart';
import 'pages/personal_page.dart';
import 'pages/controll_page.dart';

const String flask_URL = 'http://127.0.0.1:5000';
// const String flask_URL = 'http://4.227.176.245:5000';
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
        '/controll':(context) => ControllPage(),
      },
      home: ControllPage(),
    )
  );
}
