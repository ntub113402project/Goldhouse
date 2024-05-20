import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible= false;
  TextEditingController accountController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> LoginUser() async {
    var url = Uri.parse('http://4.227.176.245:5000/login');
    var response = await http.post(url, body: json.encode({
      'account': accountController.text,
      'password': passwordController.text,
    }), headers: {
      'Content-Type': 'application/json'
    });
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('登入成功'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pushNamed(context, '/personal');
                },
              ),
            ],
          );
        },
      );
    } else {
      // Handle errors
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('登入失敗'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5AE9D),
      body: Padding(
        padding: const EdgeInsetsDirectional.only(top: 0),
        child: Column(
          children: <Widget>[
            
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage( 
                    image: AssetImage('assets/Logo.png',),
                    fit: BoxFit.cover),
                ),
              ),
            ),
            
            
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, right: 40),
                    child: ListView(
                      children:<Widget>[
                        SizedBox(height: 15,),
                        Container(  
                          alignment: Alignment.centerLeft,
                          child:  Text('帳號',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
                        ),
                        SizedBox(height: 5,),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: const Color(0xFFEFEBE9),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: TextField(
                              controller: accountController,
                              decoration: InputDecoration(
                                hintText: ('請輸入帳號'),
                                hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                                border: InputBorder.none
                              ),
                            ),
                          ) 
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text( '密碼',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
                        ),
                        SizedBox(height: 5,),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: const Color(0xFFEFEBE9),
                          ),
                          child: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: TextField(                  
                              controller: passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                hintText: ('請輸入密碼'),
                                hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  onPressed: () {setState(() {_isPasswordVisible = !_isPasswordVisible;});}, 
                                  icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                              ),                  
                            )
                          ),
                          )
                        ),
                        const SizedBox(height: 30,),
                        
                        Align(
                          child: SizedBox(
                            width: 120,
                            child: TextButton(
                              onPressed: LoginUser,
                              style: TextButton.styleFrom(backgroundColor: const Color(0xFFECD8C9),),
                              child: const Text('登入',style: TextStyle(fontSize: 20,color: Colors.black),),
                            ),
                          ),
                        ),
                        const SizedBox(height:15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                            onTap: (){Navigator.pushNamed(context, '/register');},
                            child: Text('註冊帳號',style: TextStyle(color: Color(0xFF613F26)),),),
                            GestureDetector(
                            onTap: (){Navigator.pushNamed(context, '/forgetpw');},
                            child: Text('忘記密碼?',style: TextStyle(color: Color(0xFF613F26)),),),                            
                          ],
                        ),
                    
                      ],
                    ),
                  ),
                  ),
                  
                  
              ),
            
          ],
        ),
      ),
    );
  }
}