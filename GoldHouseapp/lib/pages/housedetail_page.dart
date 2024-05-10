import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'class.dart';

class HouseDetailPage extends StatefulWidget {
  
  @override
  _HouseDetailPageState createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  int _current = 0;
  
  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFECD8C9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Image.asset(
          "assets/logo_words.png",
          fit: BoxFit.contain,
          height: 70,
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              CarouselSlider(
                items: houses
                    .map((house) => Image.network(house.imageUrl, fit: BoxFit.fill, width: 1000))
                    .toList(),
                options: CarouselOptions(
                  autoPlay: true,
                  enlargeCenterPage: false,
                  aspectRatio: 1.5,
                  viewportFraction: 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _current = index;
                    });
                  },
                ),
              ),
              Positioned(
                bottom: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: houses.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => {},
                      child: Container(
                        width: 12.0,
                        height: 12.0,
                        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black).withOpacity(_current == entry.key ? 0.9 : 0.4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          SizedBox(height: 15,),
          Align(alignment: Alignment.center,
          child:  Text('中山站9分獨立門戶',style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold,),),

          ),
          
          Padding(
            padding: EdgeInsets.only(left: 10,top: 20,right: 10),
            child: Wrap(
              spacing: 5, 
              runSpacing: 5,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text('地區',style: TextStyle(fontSize: 20,color: Color(0xFF613F26),fontWeight: FontWeight.bold),),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text('房屋類型',style: TextStyle(fontSize: 20,color: Color(0xFF613F26),fontWeight: FontWeight.bold),),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text('屋主類型',style: TextStyle(fontSize: 20,color: Color(0xFF613F26),fontWeight: FontWeight.bold),),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text('樓層',style: TextStyle(fontSize: 20,color: Color(0xFF613F26),fontWeight: FontWeight.bold),),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text('型態',style: TextStyle(fontSize: 20,color: Color(0xFF613F26),fontWeight: FontWeight.bold),),
                ),
              ],
          ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20,left: 20,right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('租金\n包含',style: TextStyle(fontSize: 16,),),
                      SizedBox(width: 10,),
                      Text('水費｜管理費',style: TextStyle(fontSize: 16),)
                    ],
                  ),
                  Column(
                    children: [
                      Row(
                      children: [
                        Text('20000',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,),),
                        SizedBox(width: 10,),
                        Text('元/月',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),)
                      ],),
                      Text('押金2個月',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,),)
                  ],                
                ),
                    ],
                  )
                  
          ),
          SizedBox(height: 20,),
          Padding(padding: EdgeInsets.only(left: 10,right: 10),
          child: Card(
            color: Color(0xFFECD8C9), 
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('租期 12333', style: TextStyle(fontSize: 18)),
                      Text('入住 1233333', style: TextStyle(fontSize: 18)),
                      Text('身份 1233333', style: TextStyle(fontSize: 18)),
                      Text('其他 1233333', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('法定用途 ',style: TextStyle(fontSize: 18)),
                      Text('建物面積 1222',style: TextStyle(fontSize: 18)),
                      Text('裝潢訊息 1222',style: TextStyle(fontSize: 18)),
                      Text('產權登記 1222',style: TextStyle(fontSize: 18)),
                    ],
                  ),                  
                ],
              ),
            ),
          ),),
          
          ListTile(
            title: Text('家俱',style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
          ),
          Padding(
            padding: EdgeInsets.only(left: 10,right: 10),
            child: Container(      
              alignment: Alignment.bottomCenter,     
              decoration: BoxDecoration(
                color: Color(0xFFF5F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(20),
              child:  Wrap(
                direction: Axis.horizontal,
                spacing: 10,
                runSpacing: 10,
                children: furnitureMap.entries.map((entry) {
                  return Chip(
  labelPadding: EdgeInsets.all(4),
  avatar: CircleAvatar(
    backgroundColor: Colors.black,
    child: Icon(Icons.check, color: Colors.white),
  ),
  label: Text(
    entry.key,
    style: TextStyle(
      fontSize: 15,
      color: entry.value ? Colors.black : Colors.grey,
      decoration: entry.value ? TextDecoration.none : TextDecoration.lineThrough,
    ),
  ),
  backgroundColor: Colors.white,
  shape: StadiumBorder(
    side: BorderSide(
      color: entry.value ? Colors.black : Colors.grey,
      width: 1,
    ),
  ),
);
                }).toList(),
              ),
          ),
          ),
          ListTile(
            title: Text('房屋簡介',style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold),),
          ),
          Introduce(),
          Container(
            margin:EdgeInsets.all(15),
            alignment: Alignment.center,
            height: 100,
            decoration: BoxDecoration(
              color: Color(0xFFECD8C9),
              borderRadius: BorderRadius.circular(10)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat,size: 35,color: Color(0xFF613F26),),
                SizedBox(width: 10,),
                Text('LINE機器人',style: TextStyle(fontSize: 28,fontWeight: FontWeight.bold,color: Color(0xFF613F26)),)
              ],
            )
          )
        ],
      ),
    );
  }
}


class Introduce extends StatelessWidget {
  void _showBottomSheet(BuildContext context, String fullText) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return  Container(
          height: 700,
          padding: EdgeInsets.all(50),          
          child: SingleChildScrollView(
            child: 
              Text(fullText,style: TextStyle(fontSize: 20),),
            
          ) 
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String text = '套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房套房.';
    String shortText = text; 

    return  Card(
      color: Color(0xFFECD8C9),
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    CircleAvatar(
                  backgroundImage: NetworkImage('https://img1.591.com.tw/user/2023/05/09/1683641201851.jpg!100x100.jpg'), 
                  radius: 30.0,
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('廖小姐', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('屋主', style: TextStyle(fontSize: 15)),
                  ],
                )
                  ],
                ),
                
                SizedBox(height: 15),
                Text(shortText, style: TextStyle(fontSize: 18), maxLines: 4, overflow: TextOverflow.ellipsis),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFA58484), 
                    ),
                    onPressed: () => _showBottomSheet(context, text),
                    child: Text('查看更多',style: TextStyle(color: Color.fromRGBO(247, 247, 246, 1)),),
                ),
                ),
              ],
            ), 
      ),
    );
  }
}
