import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
                          child:  Text('電子郵件',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
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
                              decoration: InputDecoration(
                                hintText: ('請輸入電子郵件'),
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
                              decoration: InputDecoration(
                                hintText: ('請輸入密碼'),
                                hintStyle: TextStyle(color: Color.fromARGB(255, 128, 111, 111)),
                                border: InputBorder.none
                              ),
                            ),
                          )
                        ),
                        const SizedBox(height: 30,),
                        
                        Align(
                          child: SizedBox(
                            width: 120,
                            child: TextButton(
                              onPressed: () {},
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