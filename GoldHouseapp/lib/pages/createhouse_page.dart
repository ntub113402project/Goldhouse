import 'package:flutter/material.dart';

class CreateHousePage extends StatefulWidget {
  @override
  _CreateHousePageState createState() => _CreateHousePageState();
}

class _CreateHousePageState extends State<CreateHousePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFECD8C9),
        title: Image.asset(
          "assets/logo_words.png",
          fit: BoxFit.contain,
          height: 70,
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SizedBox(height: 10,),
          Align(
            alignment: Alignment.topCenter,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF613F26)),
                onPressed: () {Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AddPage()),
          );
                },
                child: Text('刊登物件',style: TextStyle(color: const Color.fromARGB(255, 245, 245, 245)),),
          ),
      )
        ],
      )
      

    );
  }
}


class AddPage extends StatefulWidget {
  
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  @override 
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Color(0xFFECD8C9),
      title: Image.asset("assets/logo_words.png",
      fit: BoxFit.contain,
      height: 70,
      ),
      centerTitle: true,  
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ),
      body: Padding(padding: EdgeInsets.only(right: 10,left: 10,bottom: 10),
        child: ListView(
        children: [
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3, 
                  offset: Offset(0, 3)
                ),
              ],
            ),
            child: ListTile(
            title: Text("縣市",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
          
          SizedBox(height: 10,),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,                   
                  offset: Offset(0, 3)
                ),
              ],
            ),
            child: ListTile(
            title: Text("房屋類型",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
          
          SizedBox(height: 10,),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,
                  offset: Offset(0, 3)
                ),
              ],
            ),            
            child: ListTile(
            title: Text("出租人",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
          SizedBox(height: 10),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,                   
                  offset: Offset(0, 3)
                ),
              ],
            ),
            child: ListTile(
            title: Text("房屋類型",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
          SizedBox(height: 10),
          InkWell(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5),
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Row(
                  children: [
                    Padding(padding: EdgeInsets.only(left: 9)),
                    Expanded(
                      flex: 1, 
                      child: Text(
                        "刊登標題",
                        style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                      ),
                    ),
                    Expanded(
                      flex: 2, 
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '請輸入刊登標題',
                          labelStyle: TextStyle(color: Color(0xFF613F26)),
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          InkWell(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5),
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Row(
                  children: [
                    Padding(padding: EdgeInsets.only(left: 9)),
                    Expanded(
                      flex: 1, 
                      child: Text(
                        "地址",
                        style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                      ),
                    ),
                    Expanded(
                      flex: 2, 
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '請填寫完整街道',
                          labelStyle: TextStyle(color: Color(0xFF613F26)),
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
                   
          SizedBox(height: 10),
          InkWell(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5),
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Row(
                  children: [
                    Padding(padding: EdgeInsets.only(left: 9)),
                    Expanded(
                      flex: 1, 
                      child: Text(
                        "租金",
                        style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                      ),
                    ),
                    Expanded(
                      flex: 2, 
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '請輸入租金',
                          labelStyle: TextStyle(color: Color(0xFF613F26)),
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ),
                     Text('元/月')
                    
                  ],
                ),
              ),
            ),
          ),
          
          
          SizedBox(height: 10,),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,
                  offset: Offset(0, 3)
                ),
              ],
            ),            
            child: ListTile(
            title: Text("租金包含",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          )
          ,
          SizedBox(height: 10,),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,
                  offset: Offset(0, 3)
                ),
              ],
            ),            
            child: ListTile(
            title: Text("家俱",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
          SizedBox(height: 10,),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,
                  offset: Offset(0, 3)
                ),
              ],
            ),            
            child: ListTile(
            title: Text("型態",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
          SizedBox(height: 10,),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,
                  offset: Offset(0, 3)
                ),
              ],
            ),            
            child: ListTile(
            title: Text("樓層",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
          SizedBox(height: 10,),
          InkWell(
            onTap: (){},
            child: Container(
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 113, 94, 94).withOpacity(0.5), 
                  blurRadius: 3,
                  offset: Offset(0, 3)
                ),
              ],
            ),            
            child: ListTile(
            title: Text("其他",style: TextStyle(color: Color(0xFF613F26),fontSize: 20),),
            trailing: Icon(Icons.arrow_forward_ios),
          ),),
          ),
        ],
      ),) 
    );
  }
}
    