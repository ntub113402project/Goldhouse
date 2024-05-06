import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'class.dart';

class HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}
List imageList = [
    {"id": 1, "image_path": 'assets/note1.jpg'},
    {"id": 2, "image_path": 'assets/note1.jpg'},
    {"id": 3, "image_path": 'assets/note1.jpg'}
  ];
final CarouselController carouselController = CarouselController();

class _HomePageState extends State<HomePage>{
  
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {    
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Color(0xFFECD8C9),
      title: Image.asset("assets/logo_words.png",
      fit: BoxFit.contain,
      height: 60,
      ),
      centerTitle: true,  
  ),
      body: ListView(
          children: [
            Stack(
              children: [
                InkWell(onTap: () {currentIndex;},
                  child: CarouselSlider(
                    items: imageList
                        .map(
                          (item) => Image.asset(
                            item['image_path'],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                        .toList(),
                    carouselController: carouselController,
                    options: CarouselOptions(
                      scrollPhysics: const BouncingScrollPhysics(),
                      autoPlay: true,
                      enlargeCenterPage: false,
                      aspectRatio: 1.5,
                      viewportFraction: 1, 
                      onPageChanged: (index, reason) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: imageList.asMap().entries.map((entry) {
                      return GestureDetector(
                        onTap: () => carouselController.animateToPage(entry.key),
                        child: Container(
                          width: currentIndex == entry.key ? 19 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3.0,
                          ),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: currentIndex == entry.key
                                  ? Colors.red
                                  : Colors.teal),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20,),
            HouseList(),
            SizedBox(height: 20,),
            Card(
              
            )
          ],
        )
    );
  }
}

class HouseList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(houses.length, (index) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: 130,
          margin: EdgeInsets.only(left: 20,right: 20,top: 10,bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {},
            child: Stack(
              children: [
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        child: Image.network(
                          houses[index].imageUrl,
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.35,
                          height: double.infinity,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${houses[index].type} | ${houses[index].name}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.clip,
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${houses[index].size}坪 ${houses[index].city}${houses[index].district}',
                                style: TextStyle(
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Row(
                    children: [
                      Text(
                        '${houses[index].price}',
                        style: TextStyle(
                          color: Color.fromARGB(255, 249, 58, 58),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' 元/月',
                        style: TextStyle(
                          color: Color.fromARGB(255, 249, 58, 58),
                          fontSize: 13
                        ),
                      ), 
                    ],
                  ),
                ),
              ],
            ),
          ),  
        );
      }),
    );
  }
}