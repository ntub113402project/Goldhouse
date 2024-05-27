import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

  
class _RegisterPageState extends State<RegisterPage> {
  int _radiogroupA=1;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  Future<void> registerUser() async {
    var url = Uri.parse('http://4.227.176.245:5000/register');
    var response = await http.post(url, body: json.encode({
      'username': usernameController.text,
      'gmail': emailController.text,
      'phone': phoneController.text,
      'gender': _radiogroupA,
      'password': passwordController.text,
    }), headers: {
      'Content-Type': 'application/json'
    });
    if (passwordController.text != confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('註冊失敗'),
            content: const Text('密碼不一致，請重新輸入'),
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
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: const Text('註冊成功'),
            actions: <Widget>[
              TextButton(
                child: const Text('確認，去登入'),
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
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
            title: Text('註冊失敗'),
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
  void _handleRadioValuChanged(int? value){
    setState((){      
      _radiogroupA=value ?? 0;
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFC5AE9D),
        leading: IconButton(
          onPressed: (){Navigator.pop(context);}, 
          icon: const Icon(Icons.arrow_back_rounded,size: 35,)) ,
        title:const Text('註冊'),
        centerTitle: true,
      ),
      body:Padding(
        padding: const EdgeInsets.only(top:10,right: 20,left: 20,),
        child: ListView(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('姓名',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
            ),
            Container(   
              padding: const EdgeInsets.all(3),           
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFFEFEBE9),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: ('請輸入中文姓名'),
                    hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                    border: InputBorder.none
                  ),
                )
              ),
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('性別',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
            ),
            Row(
              children: [
                Radio(
                  value: 1,
                  groupValue: _radiogroupA,
                  onChanged: _handleRadioValuChanged,
                ),
                const Text('男性',style: TextStyle(fontSize: 16,color: Color(0xFF613F26)),),
                Radio(
                  value: 2,
                  groupValue: _radiogroupA,
                  onChanged: _handleRadioValuChanged,
                ),
                const Text('女性',style: TextStyle(fontSize: 16,color: Color(0xFF613F26)),),
              ],
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('電子郵件',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFFEFEBE9),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: ('請輸入電子郵件'),
                    hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                    border: InputBorder.none
                  ),
                )
              ),
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('手機號碼',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFFEFEBE9),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    hintText: ('請輸入手機號碼'),
                    hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                    border: InputBorder.none
                  ),
                )
              ),
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('密碼',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
            ),
            Container(
              padding: const EdgeInsets.all(3),
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
                    hintText: ('請輸入16碼以內的英數字'),
                    hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      onPressed: () {setState(() {_isPasswordVisible = !_isPasswordVisible;});}, 
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  ),                  
                )
              ),
              ),
            ),
            const SizedBox(height: 10,),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('確認密碼',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFFEFEBE9),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: ('請輸入16碼以內的英數字'),
                    hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      onPressed: () {setState(() {_isConfirmPasswordVisible = !_isConfirmPasswordVisible;});}, 
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  ),                  
                )
                )
              ),
            ),
            const SizedBox(height:30),
            Align(
              child: SizedBox(
                width: 120,
                child: TextButton(
                  onPressed: registerUser,
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFFECD8C9),),
                  child: const Text('註冊',style: TextStyle(fontSize: 20,color: Colors.black),),
                ),
              ),
            ),
            SizedBox(height: 20,)
          ],
        ),
      ) ,
    );
  }
}