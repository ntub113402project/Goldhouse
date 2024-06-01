import 'package:flutter/material.dart';

class ForgetpwPage extends StatefulWidget {
  
  @override
  
  State<ForgetpwPage> createState() => _ForgetpwPageState();
}

class _ForgetpwPageState extends State<ForgetpwPage>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFC5AE9D),
      appBar: AppBar(
        backgroundColor: const Color(0xff613F26),
        leading: IconButton(
          onPressed: (){Navigator.pop(context);}, 
          icon: const Icon(Icons.arrow_back_rounded,size: 35,color: Color.fromRGBO(244, 244, 244, 1),)),
        title: const Text('忘記密碼',style: TextStyle(fontSize: 30,color: Color.fromRGBO(244, 244, 244, 1),fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: <Widget>[
            const Text('請在下方輸入您的電子郵件，\n我們將寄送重置密碼的方式至您的郵箱',style: TextStyle(fontSize: 20,color: Color.fromRGBO(27, 1, 1, 1)),),
            const SizedBox(height: 30,),
            Container(
              padding: const EdgeInsets.all(10),
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
            const SizedBox(height:30),
            SizedBox(
              width: 150,
              height: 60,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(backgroundColor: const Color(0xff613F26)),
                child: const Text('傳送',style: TextStyle(fontSize: 26,color:Color.fromRGBO(244, 244, 244, 1)),),
              ),
            ),
          ],
        ),
      ),
    );
  }
}