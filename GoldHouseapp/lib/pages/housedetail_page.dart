import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:io';
import 'class.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HouseDetailPage extends StatefulWidget {
  final Map<String, dynamic> houseDetails;
  
  const HouseDetailPage({super.key, required this.houseDetails});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  int _current = 0;
  
  Widget _buildIntroduce() {
    return Card(
      color: const Color(0xFFECD8C9),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://img1.591.com.tw/user/2023/05/09/1683641201851.jpg!100x100.jpg'),
                  radius: 30.0,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.houseDetails['lessorname'],
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.houseDetails['ownerType'],
                        style: TextStyle(fontSize: 15)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),
            Text(
              widget.houseDetails['description'],
              style: const TextStyle(fontSize: 18),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFA58484),
                ),
                onPressed: () => _showBottomSheet(context),
                child: const Text(
                  '查看更多',
                  style: TextStyle(color: Color.fromRGBO(247, 247, 246, 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
            height: 700,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(50),
            child: SingleChildScrollView(
              child: Text(
                widget.houseDetails['description'],
                style: const TextStyle(fontSize: 20),
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrlList = List<String>.from(widget.houseDetails['imageUrl']);
    List<Widget> allImages = imageUrlList.map<Widget>((url) => Image.network(url, fit: BoxFit.fill, width: 1000,errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {

    return const Image(image: AssetImage('assets/Logo.png'));})).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                items: allImages,
                options: CarouselOptions(
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 4),
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
                  children: List.generate(allImages.length, (index) {
                    return GestureDetector(
                      onTap: () => {},
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                                  .withOpacity(_current == index ? 0.9 : 0.4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                widget.houseDetails['title'],
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
            child: Wrap(
              spacing: 5,
              runSpacing: 12,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildInfoChip('地區', widget.houseDetails['district']),
                _buildInfoChip('房屋類型', widget.houseDetails['houseType']),
                _buildInfoChip('坪數', widget.houseDetails['size']),
                _buildInfoChip('樓層', widget.houseDetails['floor']),
                _buildInfoChip('型態', widget.houseDetails['pattern']),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child:Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '租金\n包含',
                        style: TextStyle(
                          color: Color(0xFFD1C0C0),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        '水費|電費',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFD1C0C0),
                        ),
                      )
                    ],
                  ), 
            Column(
              children: [
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${widget.houseDetails['price']}元/月',
                    style: const TextStyle(
                      color: Color(0xFFE40A0A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '${widget.houseDetails['deposit']}',
                    style: const TextStyle(
                      color: Color(0xFFD1C0C0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],)]
            ),
          ),
          SizedBox(height: 10,),
          Container(
            padding: EdgeInsets.only(top: 15, bottom: 15, left: 5, right: 5),
            margin: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFECD8C9),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.houseDetails['city']}${widget.houseDetails['address']}',
              style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF613F26),
                  fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),
          
          const ListTile(
            title: Text(
              '設備',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF613F26)),
            ),
          ),
          SizedBox(height: 5),
          Container(
            margin: const EdgeInsets.only(left: 15, right: 15),
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFECD8C9),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 3,
              runSpacing: 5,
              children: widget.houseDetails['furniture'].entries.map<Widget>((entry) {
                bool isActive = entry.value;
                return Container(
                  width: 80,
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        servicesIcons1[entry.key],
                        color: isActive
                            ? const Color(0xFF613F26)
                            : const Color.fromARGB(255, 181, 180, 180),
                        size: 40,
                      ),
                      Text(
                        entry.key,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isActive
                              ? const Color.fromARGB(255, 67, 62, 62)
                              : const Color.fromARGB(255, 181, 180, 180),
                          decoration: isActive
                              ? TextDecoration.none
                              : TextDecoration.lineThrough,
                          decorationColor:
                              const Color.fromARGB(255, 135, 135, 135),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 7,),

          const ListTile(
            title: Text(
              '房屋簡介',
              style: TextStyle( fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF613F26)),),
            ),
          
          SizedBox(height: 5,),
          _buildIntroduce(),
          SizedBox(height: 10,)
        ],
      ),
      bottomNavigationBar: const ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomAppBar(
            color: Color(0xFF613F26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.android, size: 45, color: Colors.white),
                SizedBox(
                  width: 7,
                ),
                Text(
                  'Line智能助手',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                )
              ],
            ),
          )),
    );
  }

  Widget _buildInfoChip(String label, String? value) {
    return Container(
      alignment: Alignment.center,
      width: 110,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0F0),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        value ?? '未提供',
        style: const TextStyle(
            fontSize: 20,
            color: Color(0xFF613F26),
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

class CreateHouseDetailPage extends StatefulWidget {
  final Map<String, dynamic> houseData;
  CreateHouseDetailPage({Key? key, required this.houseData}) : super(key: key);
  @override
  State<CreateHouseDetailPage> createState() => _CreateHouseDetailPageState();
}

class _CreateHouseDetailPageState extends State<CreateHouseDetailPage> {
  
  
  late Map<String, dynamic> selectedHouse;
  int _current = 0;
  @override
  void initState() {
    super.initState();
    selectedHouse = widget.houseData;
  }

  Widget _buildIntroduce() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFECD8C9),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://img1.591.com.tw/user/2023/05/09/1683641201851.jpg!100x100.jpg'),
                  radius: 30.0,
                ),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${widget.houseData['lessorname']}${widget.houseData['lessorgender']}',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.houseData['lessorType'],
                        style: TextStyle(fontSize: 15)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),
            Text(
              widget.houseData['description'],
              style: const TextStyle(fontSize: 18),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFA58484),
                ),
                onPressed: () => _showBottomSheet(context),
                child: const Text(
                  '查看更多',
                  style: TextStyle(color: Color.fromRGBO(247, 247, 246, 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
            height: 700,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(50),
            child: SingleChildScrollView(
              child: Text(
                widget.houseData['description'],
                style: const TextStyle(fontSize: 20),
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrls = List<String>.from(widget.houseData['image']);
    List<Widget> allImages = imageUrls
        .map((url) => Image.file(File(url), fit: BoxFit.fitHeight, width: 1000))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                items: allImages,
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
                  children: List.generate(allImages.length, (index) {
                    return GestureDetector(
                      onTap: () => {},
                      child: Container(
                        width: 1.0,
                        height: 12.0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black)
                                  .withOpacity(_current == index ? 0.9 : 0.4),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                widget.houseData['title'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
            child: Wrap(
              spacing: 5,
              runSpacing: 12,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    widget.houseData['district'],
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF613F26),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    widget.houseData['roomtype'],
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF613F26),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${widget.houseData['size']}坪',
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF613F26),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    '${widget.houseData['atfloor']}F / ${widget.houseData['allfloor']}F',
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF613F26),
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: 110,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0F0),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    widget.houseData['housetype'],
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF613F26),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        '租金\n包含',
                        style: TextStyle(
                          color: Color(0xFFD1C0C0),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        widget.houseData['chargecontain'].join('|'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFD1C0C0),
                        ),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${widget.houseData['charge']} 元/月',
                        style: const TextStyle(
                          color: Color(0xFFE40A0A),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.houseData['deposit'],
                        style: const TextStyle(
                          color: Color(0xFFD1C0C0),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ],
              )),
          const SizedBox(
            height: 15,
          ),
          Container(
            padding: EdgeInsets.only(top: 15, bottom: 15, left: 5, right: 5),
            margin: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFECD8C9),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '${widget.houseData['city']}${widget.houseData['district']}${widget.houseData['address']}',
              style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF613F26),
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Container(
            padding: EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5),
            margin: EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFECD8C9),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text('寵物：${widget.houseData['pet']}',
                      style: TextStyle(fontSize: 18, color: Color(0xFF613F26))),
                  Text('性別限制：${widget.houseData['genderlimit']}',
                      style: TextStyle(fontSize: 18, color: Color(0xFF613F26))),
                ],
              ),
            ),
          ),
          const ListTile(
            title: Text(
              '設備',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF613F26)),
            ),
          ),
          SizedBox(height: 5),
          Container(
            margin: const EdgeInsets.only(left: 15, right: 15),
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFECD8C9),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: 3,
              runSpacing: 5,
              children: allservices.map<Widget>((service) {
                bool isActive = widget.houseData['service'].contains(service);
                return Container(
                  width: 80,
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        servicesIcons[service],
                        color: isActive
                            ? const Color(0xFF613F26)
                            : const Color.fromARGB(255, 181, 180, 180),
                        size: 40,
                      ),
                      Text(
                        service,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: isActive
                              ? const Color.fromARGB(255, 67, 62, 62)
                              : const Color.fromARGB(255, 181, 180, 180),
                          decoration: isActive
                              ? TextDecoration.none
                              : TextDecoration.lineThrough,
                          decorationColor:
                              const Color.fromARGB(255, 135, 135, 135),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 5),
          const ListTile(
            title: Text(
              '房屋簡介',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF613F26)),
            ),
          ),
          const SizedBox(height: 5),
          _buildIntroduce(),
          SizedBox(
            height: 10,
          )
        ],
      ),
      bottomNavigationBar: const ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomAppBar(
            color: Color(0xFF613F26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.android, size: 45, color: Colors.white),
                SizedBox(
                  width: 7,
                ),
                Text(
                  'Line智能助手',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                )
              ],
            ),
          )),
    );
  }
}
