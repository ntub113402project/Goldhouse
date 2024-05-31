import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';

class ModifyPersonalPage extends StatefulWidget {
  @override
  _ModifyPersonalPageState createState() => _ModifyPersonalPageState();
}

class _ModifyPersonalPageState extends State<ModifyPersonalPage> {
  File? _image;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _gmailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  int member_id = 0; //add
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
      member_id = prefs.getInt('member_id') ?? 0;
      _gender = (genderCode == 1) ? '男性' : '女性';
    });
  }

  Future<void> _saveUserData() async {
    try {
      final response = await http.post(
        Uri.parse('$flask_URL/update_user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'member_id':member_id,
          'username': _nameController.text,
          'gmail': _gmailController.text,
          'phone': _phoneController.text,
        }),
      );

      if (response.statusCode == 200) {
        // 更新成功
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('資料已更新')),
        );
        // 更新 SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _nameController.text);
        await prefs.setString('gmail', _gmailController.text);
        await prefs.setString('phone', _phoneController.text);
      } else {
        // 處理更新失敗
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗')),
        );
      }
    } catch (error) {
      print('Error: $error');
      // 無法連線至 Flask API
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法連線至伺服器')),
      );
    }
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
                    onPressed: _saveUserData,
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