import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HouseDetailPage extends StatefulWidget {
  final Map<String, dynamic> houseDetails;
  const HouseDetailPage({super.key, required this.houseDetails});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    List<String> imageUrlList = List<String>.from(widget.houseDetails['imageUrl']);
    List<Widget> allImages = imageUrlList.map<Widget>((url) => Image.network(url, fit: BoxFit.fill, width: 1000)).toList();

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
                        width: 12.0,
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
          const SizedBox(
            height: 15,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                widget.houseDetails['title'],
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
              runSpacing: 5,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildInfoChip('地區', widget.houseDetails['area']),
                _buildInfoChip('房屋類型', widget.houseDetails['houseType']),
                _buildInfoChip('屋主類型', widget.houseDetails['ownerType']),
                _buildInfoChip('樓層', widget.houseDetails['floor']),
                _buildInfoChip('型態', widget.houseDetails['pattern']),
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
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      widget.houseDetails['includes'],
                      style: const TextStyle(fontSize: 16),
                    )
                  ],
                ),
                Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '${widget.houseDetails['price']}元/月',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          '元/月',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    Text(
                      '押金${widget.houseDetails['deposit']}個月',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Card(
              color: const Color(0xFFECD8C9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('租期: ${widget.houseDetails['rentPeriod']}', style: const TextStyle(fontSize: 18)),
                        Text('入住: ${widget.houseDetails['moveInDate']}', style: const TextStyle(fontSize: 18)),
                        Text('身份: ${widget.houseDetails['identity']}', style: const TextStyle(fontSize: 18)),
                        Text('其他: ${widget.houseDetails['other']}', style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('法定用途: ${widget.houseDetails['legalUse']}', style: const TextStyle(fontSize: 18)),
                        Text('建物面積: ${widget.houseDetails['areaSize']}', style: const TextStyle(fontSize: 18)),
                        Text('裝潢訊息: ${widget.houseDetails['decoration']}', style: const TextStyle(fontSize: 18)),
                        Text('產權登記: ${widget.houseDetails['propertyRegistration']}', style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const ListTile(
            title: Text(
              '家俱',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Container(
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Wrap(
                direction: Axis.horizontal,
                spacing: 10,
                runSpacing: 10,
                children: widget.houseDetails['furniture'].entries.map<Widget>((entry) {
                  return Chip(
                    labelPadding: const EdgeInsets.all(4),
                    avatar: const CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    label: Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 15,
                        color: entry.value ? Colors.black : Colors.grey,
                        decoration: entry.value
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
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
          const ListTile(
            title: Text(
              '房屋簡介',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          Introduce(description: widget.houseDetails['description']),
          Container(
              margin: const EdgeInsets.all(15),
              alignment: Alignment.center,
              height: 100,
              decoration: BoxDecoration(
                  color: const Color(0xFFECD8C9),
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat,
                    size: 35,
                    color: Color(0xFF613F26),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'LINE機器人',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF613F26)),
                  )
                ],
              ))
        ],
      ),
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
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}

class Introduce extends StatelessWidget {
  final String description;

  const Introduce({super.key, required this.description});

  void _showBottomSheet(BuildContext context, String fullText) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
            height: 700,
            padding: const EdgeInsets.all(50),
            child: SingleChildScrollView(
              child: Text(
                fullText,
                style: const TextStyle(fontSize: 20),
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String shortText = description;

    return Card(
      color: const Color(0xFFECD8C9),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
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
                    Text('廖小姐',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('屋主', style: TextStyle(fontSize: 15)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 15),
            Text(shortText,
                style: const TextStyle(fontSize: 18),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFA58484),
                ),
                onPressed: () => _showBottomSheet(context, description),
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
}