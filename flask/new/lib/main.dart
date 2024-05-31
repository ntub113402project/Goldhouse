import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'modify_person.dart';
import 'search_page.dart';

void main() {
  runApp(MyApp());
}

// String flask_URL = 'http://4.227.176.245:5000';
const String flask_URL = 'http://127.0.0.1:5000';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/members': (context) => AllMembersScreen(),
        '/change_password':(context) => ChangePassword(),
        '/search_page': (context) => SearchPage(),
        '/modify_person':(context) => ModifyPersonalPage(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('註冊'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('登入'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/members');
              },
              child: Text('所有會員'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/change_password');
              },
              child: Text('更改密碼'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/search_page');
              },
              child: Text('查詢'),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget{
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController genderController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController gmailController = TextEditingController();

  Future<void> register(BuildContext context) async {
    try{
      final response = await http.post(
      Uri.parse('$flask_URL/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'gender': genderController.text,
        'password': passwordController.text,
        'username':nameController.text,
        'phone':phoneController.text,
        'gmail':gmailController.text
        }),
      );
      if (response.statusCode == 200) {
        // 處理註冊成功
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User registered successfully')),
        );
      } else if(response.statusCode == 422){
        // 處理註冊失敗
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        final Map<String, dynamic> responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? 'Unknown error occurred')),
        );
      } else {
        //處理 empty field
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        final Map<String, dynamic> responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? 'Unknown error occurred')),
        );
      }
    }catch(error){
      //無法連線至 flask api
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot connect to Internet or system is under maintenance')),
      );
    }
  }

  bool register_obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('註冊'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: gmailController,
              decoration: InputDecoration(labelText: 'Gmail'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(Icons.visibility),
                  onPressed: (){
                    setState((){
                      register_obscureText = !register_obscureText;
                    });
                  },
                ),
              ),
              obscureText: register_obscureText,
              inputFormatters: [LengthLimitingTextInputFormatter(16)],
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            SizedBox(height: 16),
            Row(
            children: <Widget>[
                _buildGenderButton('男', '1'),
                SizedBox(width: 10),
                _buildGenderButton('女', '2'),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                register(context);
              },
              child: Text('註冊'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(String gender, String value) {
    Color borderColor = Colors.grey;
    Color iconColor = Colors.grey;
    Color containerColor = Colors.transparent;
    if (genderController.text == value) {
      borderColor = value == '1' ? Colors.blue : Colors.pink;
      iconColor = value == '1' ? Colors.blue : Colors.pink; // 根据性别值确定图标颜色
      containerColor = value == '1' ? Colors.lightBlue.withOpacity(0.5) : Colors.pink.withOpacity(0.5); // 根据性别值确定背景颜色
    }

    return InkWell(
      onTap: () {
        setState(() {
          genderController.text = value;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(10),
          color: containerColor,
        ),
        child: Center(
          child: genderController.text == value
            ? Icon(Icons.check, color: iconColor)
            : Text(gender),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget{
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController gmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    try{
      final response = await http.post(
        Uri.parse('$flask_URL/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'gmail': gmailController.text,
          'password': passwordController.text,
        }),
      );
      if (response.statusCode == 200) {
        // 處理登入成功
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful')),
        );

        final Map<String, dynamic> responseData = json.decode(response.body); 
        final members = responseData['members'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('member_id', members['member_id']);
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
                    Navigator.pushNamed(context, '/modify_person', arguments: members);
                  },
                ),
              ],
            );
          },
        );
      } else if(response.statusCode == 400){
        // 處理密碼錯誤
        passwordController.clear();
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong password')),
        );
      }else {
        // 處理登入失敗
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User does not exists')),
        );
      }
    }catch(error){
      print('Error: $error');
      //無法連線至 flask api
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot connect to Internet or system is under maintenance')),
      );

    }
  }

  bool login_obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登入'),
      ),
      body: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: gmailController,
              decoration: InputDecoration(labelText: 'Gmail'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: login_obscureText ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                  onPressed: (){
                    setState((){
                      login_obscureText = !login_obscureText;
                    });
                  },
                ),
              ),
              obscureText: login_obscureText,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                login(context);
              },
              child: Text('登入'),
            ),
          ],
        ),
      ),
    );
  }
}

class AllMembersScreen extends StatelessWidget { 
  Future<List<dynamic>> fetchMembers(BuildContext context) async {
    try{
      final response = await http.get(Uri.parse('$flask_URL/members'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {  
        throw Exception('Failed to load members');
      }
    }catch(error){
      //無法連線至 flask api
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot connect to Internet or system is under maintenance')),
      );
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('所有會員'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchMembers(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<dynamic>? members = snapshot.data;
            return DataTable(
              columns: [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Gmail')),
                DataColumn(label: Text('Gender'))
              ],
              rows: members?.map((member){
                return DataRow(cells: [
                  DataCell(Text(member['id'].toString())),
                  DataCell(Text(member['username'].toString())),
                  DataCell(Text(member['phone'].toString())),
                  DataCell(Text(member['gmail'].toString())),
                  DataCell(Text(member['gender'].toString())),
                ]);
              }).toList() ?? [],
            );
          }
        },
      ),
    );
  }
}

class ChangePassword extends StatefulWidget {
  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController gmailController = TextEditingController();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  Future<void> changePassword() async {
    try{
      final response = await http.post(
        Uri.parse('$flask_URL/change_password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'gmail':gmailController.text,
          'old_password': oldPasswordController.text,
          'new_password': newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // 密码已成功更改
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );
      } else if (response.statusCode == 400) {
        // 无效的凭据
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong password')),
        );
      } else if(response.statusCode == 404){
        // 其他错误
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User does not exists')),
        );
      }
    }catch(error){
      //無法連線至 flask api
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot connect to Internet or system is under maintenance')),
      );
    }
  }

  bool OldPasseord_obscureText = true;
  bool NewPassword_obscureText = true;
  bool ConfirmNewPassword_obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: gmailController,
              decoration: InputDecoration(labelText: 'Gmail'),
            ),
            TextField(
              controller: oldPasswordController,
              obscureText: OldPasseord_obscureText,
              decoration: InputDecoration(
                labelText: 'Old Password',
                suffixIcon: IconButton(
                  icon: OldPasseord_obscureText ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                  onPressed: (){
                    setState((){
                      OldPasseord_obscureText = !OldPasseord_obscureText;
                    });
                  },
                ),
              ),
            ),
            TextField(
              controller: newPasswordController,
              obscureText: NewPassword_obscureText,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: NewPassword_obscureText ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                  onPressed: (){
                    setState((){
                      NewPassword_obscureText = !NewPassword_obscureText;
                    });
                  },
                ),
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: ConfirmNewPassword_obscureText,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                suffixIcon: IconButton(
                  icon: ConfirmNewPassword_obscureText ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                  onPressed: (){
                    setState((){
                      ConfirmNewPassword_obscureText = !ConfirmNewPassword_obscureText;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed:(){
                if (newPasswordController.text == confirmPasswordController.text) {
                  changePassword();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('New passwords do not match')),
                  );
                }
              },
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}