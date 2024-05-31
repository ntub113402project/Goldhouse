import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'controll_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else {
          if (snapshot.data == true) {
            return PersonalPage();
          } else {
            return LoginFirstPage();
          }
        }
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  File? _image;
  String? username;
  String? gmail;

  Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadmembers();
    requestPermissions();
  }

  Future<void> _loadmembers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
      gmail = prefs.getString('gmail');
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => ControllPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: ListView(
      children: [
        Padding(padding: EdgeInsets.only(top: 50)),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 200,
              margin: EdgeInsets.only(top: 10),
              padding: EdgeInsets.only(top: 50),
              decoration: BoxDecoration(
                color: Color(0xFFECD8C9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF613F26), width: 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(username ?? '',
                      style: TextStyle(
                          color: Color(0xFF613F26),
                          fontWeight: FontWeight.bold,
                          fontSize: 25)),
                  SizedBox(
                    height: 3,
                  ),
                  Text(gmail ?? '',
                      style: TextStyle(color: Color(0xFF613F26), fontSize: 16)),
                  SizedBox(
                    height: 5,
                  ),
                  ElevatedButton(
                      onPressed: _logout,
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(
                              Color.fromARGB(255, 156, 146, 139))),
                      child: Text(
                        '登出',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ))
                ],
              ),
            ),
            Positioned(
                top: -45,
                child: GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('相簿'),
                                onTap: () {
                                  _pickImage(ImageSource.gallery);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.camera_alt),
                                title: Text('相機'),
                                onTap: () {
                                  _pickImage(ImageSource.camera);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 235, 189, 155),
                      border: Border.all(color: Color(0xFF613F26), width: 10),
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: ClipOval(
                      child: _image == null
                          ? Image.asset('assets/Logo.png', fit: BoxFit.cover)
                          : Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                )),
          ],
        ),
        Container(
          margin: EdgeInsets.only(top: 35, left: 30, right: 30, bottom: 20),
          decoration: BoxDecoration(
              color: Color.fromARGB(255, 252, 252, 252),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 73, 65, 65).withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ]),
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ModifyPersonalPage()),
                  );
                },
                leading: Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF613F26),
                ),
                title: Text(
                  "個人資料",
                  style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                ),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              Divider(
                color: Color(0xFF613F26),
                height: 20,
              ),
              ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ModifyPasswordPage()),
                  );
                },
                leading: Icon(
                  Icons.lock,
                  size: 30,
                  color: Color(0xFF613F26),
                ),
                title: Text(
                  "更改密碼",
                  style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                ),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              Divider(
                color: Color(0xFF613F26),
                height: 20,
              ),
              ListTile(
                leading: Icon(
                  Icons.favorite_rounded,
                  size: 30,
                  color: Color(0xFF613F26),
                ),
                title: Text(
                  "我的收藏",
                  style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                ),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              Divider(
                color: Color(0xFF613F26),
                height: 20,
              ),
              ListTile(
                leading: Icon(
                  Icons.loyalty,
                  size: 30,
                  color: Color(0xFF613F26),
                ),
                title: Text(
                  "瀏覽紀錄",
                  style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                ),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ],
    ));
  }
}

class ModifyPersonalPage extends StatefulWidget {
  @override
  _ModifyPersonalPageState createState() => _ModifyPersonalPageState();
}

class _ModifyPersonalPageState extends State<ModifyPersonalPage> {
  File? _image;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _gmailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  String _gender = '';

  Future<void> requestPermissions() async {
    await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    requestPermissions();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('username') ?? '';
      _gmailController.text = prefs.getString('gmail') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      int genderCode = int.parse(prefs.getString('gender') ?? '1');
      _gender = (genderCode == 1) ? '男性' : '女性';
    });
  }

  // Future<void> _saveUserData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   prefs.setString('username', _nameController.text);
  //   prefs.setString('gmail', _gmailController.text);
  //   prefs.setString('phone', _phoneController.text);
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text('資料已更新')),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFECD8C9),
          title: Text(
            '個人資料修改',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          centerTitle: true,
        ),
        body: ListView(
          children: [
            Container(
              margin: EdgeInsets.only(left: 15, right: 15, top: 20),
              padding: EdgeInsets.only(left: 15, right: 15, top: 20),
              decoration: BoxDecoration(
                color: Color(0xFFECD8C9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color(0xFF613F26), width: 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    height: 30,
                  ),
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(Icons.photo_library),
                                  title: Text('相簿'),
                                  onTap: () {
                                    _pickImage(ImageSource.gallery);
                                    Navigator.of(context).pop();
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.camera_alt),
                                  title: Text('相機'),
                                  onTap: () {
                                    _pickImage(ImageSource.camera);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF613F26), width: 10),
                        borderRadius: BorderRadius.circular(80),
                      ),
                      child: ClipOval(
                        child: _image == null
                            ? Image.asset('assets/Logo.png', fit: BoxFit.cover)
                            : Image.file(_image!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      suffixIcon: Icon(Icons.create_rounded),
                      labelText: '姓名',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF615AAB),
                          width: 3,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 33, 26, 26),
                          width: 3,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 20),
                  Container(
                      width: MediaQuery.of(context).size.width * 0.82,
                      padding: EdgeInsets.only(top: 15, bottom: 15, left: 10),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Color.fromARGB(255, 33, 26, 26), width: 3),
                          borderRadius: BorderRadius.circular(5)),
                      child: Row(
                        children: [
                          Icon(Icons.transgender_rounded),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            '$_gender (不可修改)',
                            style: TextStyle(
                                fontSize: 17,
                                color: Color.fromARGB(255, 113, 113, 113)),
                          ),
                        ],
                      )),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _gmailController,
                    decoration: InputDecoration(
                      suffixIcon: Icon(Icons.create_rounded),
                      labelText: '電子郵件',
                      prefixIcon: Icon(Icons.mail_rounded),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF615AAB),
                          width: 3,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 33, 26, 26),
                          width: 3,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      suffixIcon: Icon(Icons.create_rounded),
                      labelText: '電話號碼',
                      prefixIcon: Icon(Icons.phone_rounded),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF615AAB),
                          width: 3,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromARGB(255, 33, 26, 26),
                          width: 3,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF613F26)),
                    onPressed: () {},
                    child: Text(
                      '確認',
                      style: TextStyle(
                          color: const Color.fromARGB(255, 245, 245, 245)),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            )
          ],
        ));
  }
}

class ModifyPasswordPage extends StatefulWidget {
  @override
  _ModifyPasswordPageState createState() => _ModifyPasswordPageState();
}

class _ModifyPasswordPageState extends State<ModifyPasswordPage> {
  bool _isPasswordVisible = false;
  bool _isPasswordVisible1 = false;
  bool _isPasswordVisible2 = false;
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> changePassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String gmail = prefs.getString('gmail') ?? '';
    String oldPassword = _oldPasswordController.text;
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('錯誤'),
          content: Text('新密碼與確認密碼不一致'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('確認'),
            ),
          ],
        ),
      );
      return;
    }

    var url = Uri.parse('http://4.227.176.245:5000/change_password');
    var response = await http.post(url, body: json.encode({
      'gmail': gmail,
      'old_password': oldPassword,
      'new_password': newPassword,
    }), headers: {
      'Content-Type': 'application/json'
    });

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('成功'),
          content: Text(json.decode(response.body)['message']),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('確認'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('錯誤'),
          content: Text(json.decode(response.body)['error']),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('確認'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFECD8C9),
          title: Text(
            '更改密碼',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(left: 15, right: 15, top: 30),
            padding: EdgeInsets.only(left: 15, right: 15, top: 40, bottom: 20),
            decoration: BoxDecoration(
              color: Color(0xFFECD8C9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFF613F26), width: 10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: '舊密碼',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                      icon: Icon(_isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF615AAB),
                        width: 3,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 33, 26, 26),
                        width: 3,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isPasswordVisible1,
                  decoration: InputDecoration(
                    labelText: '新密碼(16碼內英數字)',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible1 = !_isPasswordVisible1;
                        });
                      },
                      icon: Icon(_isPasswordVisible1
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF615AAB),
                        width: 3,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 33, 26, 26),
                        width: 3,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isPasswordVisible2,
                  decoration: InputDecoration(
                    labelText: '確認新密碼(16碼內英數字)',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible2 = !_isPasswordVisible2;
                        });
                      },
                      icon: Icon(_isPasswordVisible2
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFF615AAB),
                        width: 3,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 33, 26, 26),
                        width: 3,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF613F26)),
                  onPressed: changePassword,
                  child: Text(
                    '確認',
                    style: TextStyle(
                        color: const Color.fromARGB(255, 245, 245, 245)),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
