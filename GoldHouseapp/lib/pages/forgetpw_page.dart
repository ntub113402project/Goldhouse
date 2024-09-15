import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ForgetpwPage extends StatefulWidget {
  @override
  State<ForgetpwPage> createState() => _ForgetpwPageState();
}

class _ForgetpwPageState extends State<ForgetpwPage> {
  TextEditingController gmailController = TextEditingController();
  TextEditingController verifyController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool showverifyfield = false;
  bool isVerifyButtonEnable = false;

  Future<void> sendemail() async {
    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/forget_password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'gmail': gmailController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        showverifyfield = true;
      });
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: const Text('已發送驗證碼'),
              actions: <Widget>[
                TextButton(
                  child: const Text('確認'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          });
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
    Future.delayed(Duration(minutes: 10), () {
      if (mounted) {
        setState(() {
          showverifyfield = false;
          verifyController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        });
      }
    });
  }

  Future verifycode() async {
    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/verify_code'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'gmail': gmailController.text,
        'code': verifyController.text,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        verifyController.clear();
        showverifyfield = false;
      });
      showChangePasswordDialog(context);
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

  Future resetpassword() async {
    if (confirmPasswordController.text != newPasswordController.text) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('密碼與確認密碼不一致'),
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
      return;
    }

    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/reset_password'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'gmail': gmailController.text,
        'new_password': newPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              content: const Text('密碼修改成功'),
              actions: <Widget>[
                TextButton(
                  child: const Text('去登入'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                ),
              ],
            );
          });
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
  void initState() {
    super.initState();
    verifyController.addListener(() {
      setState(() {
        isVerifyButtonEnable = verifyController.text.length == 6;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFC5AE9D),
      appBar: AppBar(
        backgroundColor: const Color(0xff613F26),
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 35,
              color: Color.fromRGBO(244, 244, 244, 1),
            )),
        title: const Text(
          '忘記密碼',
          style: TextStyle(
              fontSize: 30,
              color: Color.fromRGBO(244, 244, 244, 1),
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: <Widget>[
            const Text(
              '請在下方輸入您的電子郵件，\n我們將寄送驗證碼至您的郵箱',
              style:
                  TextStyle(fontSize: 20, color: Color.fromRGBO(27, 1, 1, 1)),
            ),
            const SizedBox(
              height: 30,
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFFEFEBE9),
              ),
              child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: TextField(
                    controller: gmailController,
                    decoration: InputDecoration(
                        hintText: ('請輸入電子郵件'),
                        hintStyle: TextStyle(
                            color: Color.fromARGB(255, 128, 111, 111)),
                        border: InputBorder.none,
                        suffixIcon: TextButton(
                            onPressed: sendemail,
                            style: TextButton.styleFrom(
                                backgroundColor: Color(0xff613F26)),
                            child: Text(
                              '傳送驗證碼',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 250, 247, 247)),
                            ))),
                  )),
            ),
            const SizedBox(height: 30),
            if (showverifyfield == true)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: const Color(0xFFEFEBE9),
                ),
                child: Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: TextField(
                      controller: verifyController,
                      // keyboardType: TextInputType.number,
                      // inputFormatters: <TextInputFormatter>[
                      //   FilteringTextInputFormatter.digitsOnly
                      // ],
                      decoration: const InputDecoration(
                          hintText: ('請輸入驗證碼'),
                          hintStyle: TextStyle(
                              color: Color.fromARGB(255, 128, 111, 111)),
                          border: InputBorder.none),
                    )),
              ),
            SizedBox(
              height: 30,
            ),
            if (showverifyfield == true)
              SizedBox(
                width: 150,
                height: 60,
                child: TextButton(
                  onPressed: isVerifyButtonEnable ? verifycode : null,
                  style: TextButton.styleFrom(
                    backgroundColor: isVerifyButtonEnable
                        ? const Color(0xff613F26)
                        : Colors.grey,
                  ),
                  child: const Text(
                    '驗證',
                    style: TextStyle(
                        fontSize: 26, color: Color.fromRGBO(244, 244, 244, 1)),
                  ),
                ),
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('更新密碼'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(labelText: '新密碼'),
                obscureText: true,
              ),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(labelText: '確認新密碼'),
                obscureText: true,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('確認'),
              onPressed: resetpassword,
            ),
          ],
        );
      },
    );
  }
}
