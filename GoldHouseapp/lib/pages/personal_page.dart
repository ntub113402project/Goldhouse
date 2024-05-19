import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';



class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  File? _image;
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
              border: Border.all(color: Color(0xFF613F26),width: 10),
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
                Text('廖芸珮',style: TextStyle(color: Color(0xFF613F26), fontWeight: FontWeight.bold, fontSize: 25)),
                SizedBox(height: 3,),
                Text('penny43589201@gmail.com',style: TextStyle(color: Color(0xFF613F26), fontSize: 16)),
                SizedBox(height: 5,),
                ElevatedButton(onPressed: (){},style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Color.fromARGB(255, 156, 146, 139))), child: Text('登出',style: TextStyle(color: Colors.white,fontSize: 15),))
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
                  color: Colors.amber,
                  border: Border.all(color: Color(0xFF613F26),width: 10),
                  borderRadius: BorderRadius.circular(80),
                ),
                child: ClipOval(
                  child: _image == null
                      ? Image.asset('assets/Logo.png', fit: BoxFit.cover)
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
            )
          ),
        ],),
            Container(
              margin: EdgeInsets.only(top: 30,left: 20,right: 20,bottom: 30),
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
                    ]
                  ),
                  child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.person,
                        size: 30,
                        color: Color(0xFF613F26),
                      ),
                      title: Text("個人資料",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                    Divider(color: Color(0xFF613F26),height: 10,),
                    ListTile(
                      leading: Icon(
                        Icons.favorite_rounded,
                        size: 30,
                        color: Color(0xFF613F26),
                      ),
                      title: Text("更改密碼",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                    Divider(color:Color(0xFF613F26),height: 10,),
                    ListTile(
                      leading: Icon(
                        Icons.loyalty,
                        size: 30,
                        color: Color(0xFF613F26),
                      ),
                      title: Text("我的收藏",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                    Divider(color:Color(0xFF613F26),height: 10,),
                    ListTile(
                      leading: Icon(
                        Icons.group,
                        size: 30,
                        color: Color(0xFF613F26),
                      ),
                      title: Text("瀏覽紀錄",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                    Divider(color:Color(0xFF613F26),height: 10,),
                    ListTile(
                      leading: Icon(
                        Icons.question_answer,
                        size: 30,
                        color: Color(0xFF613F26),
                      ),
                      title: Text("個人資料",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
                      trailing: Icon(Icons.question_mark),
                    ),
                  ],
                  
                ),
                ),
          ],
    ));
  }
}