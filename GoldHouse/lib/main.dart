import 'package:flutter/material.dart';
import 'pages/register_page.dart';
import 'pages/login_page.dart';
import 'pages/forgetpw_page.dart';
import 'pages/home_page.dart';
void main() {
  runApp(
    MaterialApp(  
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/register':(context) => RegisterPage(),
        '/login':(context) => LoginPage(),
        '/forgetpw':(context) => ForgetpwPage(),
        
      },
      home: HomePage(),
    )
  );
}
