import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginFirstPage extends StatelessWidget {
  const LoginFirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: Image.asset(
          "assets/logo_words.png",
          fit: BoxFit.contain,
          height: 70,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF613F26)),
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          child: const Text(
            '按這裡登入',
            style: TextStyle(color:  Color.fromARGB(255, 245, 245, 245)),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  TextEditingController gmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> loginUser() async {
    var url = Uri.parse('$flask_URL/login');
    var response = await http.post(url,
        body: json.encode({
          'gmail': gmailController.text,
          'password': passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'});
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final members = responseData['members'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', members['username']);
      await prefs.setString('gmail', members['gmail']);
      await prefs.setString('phone', members['phone']);
      await prefs.setString('gender', members['gender']);
      await prefs.setBool('isLoggedIn', true);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('登入成功'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pushNamed(context, '/controll', arguments: members);
                },
              ),
            ],
          );
        },
      );
    } else {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final errorMessage = responseData['error'] ?? '未知錯誤';
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(errorMessage),
            actions: <Widget>[
              TextButton(
                child: const Text('確認'),
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
                child: Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(
                              'assets/Logo.png',
                            ),
                            fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                        top: 40,
                        left: 12,
                        child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 35,
                              color: Colors.black,
                            ))),
                  ],
                )),
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
                    children: <Widget>[
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          '電子郵件',
                          style:
                              TextStyle(fontSize: 22, color: Color(0xFF613F26)),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: const Color(0xFFEFEBE9),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: TextField(
                              controller: gmailController,
                              decoration: const InputDecoration(
                                  hintText: ('請輸入電子郵件'),
                                  hintStyle: TextStyle(
                                      color:
                                          Color.fromARGB(255, 128, 111, 111)),
                                  border: InputBorder.none),
                            ),
                          )),
                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '密碼',
                          style:
                              TextStyle(fontSize: 22, color: Color(0xFF613F26)),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: const Color(0xFFEFEBE9),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: TextField(
                                controller: passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: ('請輸入密碼'),
                                  hintStyle: const TextStyle(
                                      color:
                                          Color.fromARGB(255, 128, 111, 111)),
                                  border: InputBorder.none,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                    icon: Icon(_isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                  ),
                                )),
                          )),
                      const SizedBox(
                        height: 30,
                      ),
                      Align(
                        child: SizedBox(
                          width: 120,
                          child: TextButton(
                            onPressed: loginUser,
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFECD8C9),
                            ),
                            child: const Text(
                              '登入',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              '註冊帳號',
                              style: TextStyle(color: Color(0xFF613F26)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/forgetpw');
                            },
                            child: const Text(
                              '忘記密碼?',
                              style: TextStyle(color: Color(0xFF613F26)),
                            ),
                          ),
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
