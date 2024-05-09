import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _radiogroupA=0;

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
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: ('請輸入姓名'),
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
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
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
              child: Text('密碼',style: TextStyle(fontSize: 22,color: Color(0xFF613F26)),),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color(0xFFEFEBE9),
              ),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: ('請輸入密碼'),
                    hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                    border: InputBorder.none
                  ),
                )
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
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: ('請再次輸入密碼'),
                    hintStyle: TextStyle( color: Color.fromARGB(255, 128, 111, 111)),
                    border: InputBorder.none
                  ),
                )
              ),
            ),
            const SizedBox(height:30),
            Align(
              child: SizedBox(
                width: 120,
                child: TextButton(
                  onPressed: () {},
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