import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'class.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'housecard.dart';

class HouseDetailPage extends StatefulWidget {
  final Map<String, dynamic> houseDetails;

  const HouseDetailPage({super.key, required this.houseDetails});

  @override
  State<HouseDetailPage> createState() => _HouseDetailPageState();
}

class _HouseDetailPageState extends State<HouseDetailPage> {
  int _current = 0;
  List<Map<String, dynamic>> similarHouses = [];
  

  Future<int?> _getMemberId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');
    return memberId;
  }

  void _onBottomAppBarPressed() async {
    int? memberId = await _getMemberId();
    String hid = widget.houseDetails['hid'].toString();

    if (memberId != null && hid.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://4.227.176.245:5000/save_click'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'member_id': memberId,
          'hid': hid,
        }),
      );

      if (response.statusCode == 200) {
        String message = "hid:$hid";
        String encodedMessage = Uri.encodeComponent(message);

        final url = Uri.parse(
            "https://line.me/R/oaMessage/%40204wjleq?$encodedMessage");
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        } else {
          ('無法連結 $url');
        }
      } else {
        ('無法連線: ${response.statusCode}');
      }
    } else {
      ('尚未登入或沒有hid');
    }
  }

  Future<void> clickrecord(int memberId, String hid) async {
    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/record_click'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'member_id': memberId,
        'hid': hid,
      }),
    );

    if (response.statusCode == 200) {
      ('Click recorded successfully');
    } else {
      ('Failed to record click: ${response.body}');
    }
  }

  Future<void> _toggleFavorite(int index, String hid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');
    if (memberId != null) {
      bool isCurrentlyFavorite = FavoriteManager().favoriteHids.contains(hid);

      String apiEndpoint = 'http://4.227.176.245:5000/favorites';
      String method = isCurrentlyFavorite ? 'DELETE' : 'POST';

      setState(() {
        if (isCurrentlyFavorite) {
          FavoriteManager().favoriteHids.remove(hid);
        } else {
          FavoriteManager().favoriteHids.add(hid);
        }
        similarHouses[index]['isFavorite'] = !isCurrentlyFavorite;
      });

      final request = http.Request(method, Uri.parse(apiEndpoint))
        ..headers['Content-Type'] = 'application/json; charset=UTF-8'
        ..body = jsonEncode(<String, String>{
          'member_id': memberId.toString(),
          'hid': hid,
        });

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $responseBody')),
        );

        // 如果後端更新失敗，恢復本地收藏狀態
        setState(() {
          if (isCurrentlyFavorite) {
            FavoriteManager().favoriteHids.add(hid);
          } else {
            FavoriteManager().favoriteHids.remove(hid);
          }
          similarHouses[index]['isFavorite'] = isCurrentlyFavorite;
        });
      } else {
        // 成功後更新 SharedPreferences
        prefs.setStringList(
            'favoriteHids', FavoriteManager().favoriteHids.toList());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
    }
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
                widget.houseDetails['content'],
                style: const TextStyle(fontSize: 20),
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrlList =
        List<String>.from(widget.houseDetails['imageUrl']);
    if (imageUrlList.isEmpty) {
      imageUrlList = ['assets/Logo.png'];
    }
    List<Widget> allImages = imageUrlList
        .map<Widget>((url) => Image.network(url, fit: BoxFit.fill, width: 1000,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
              return const Image(image: AssetImage('assets/Logo.png'));
            }))
        .toList();
    similarHouses =
        List<Map<String, dynamic>>.from(widget.houseDetails['similarhouses']);

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
                    autoPlayInterval: const Duration(seconds: 4),
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
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text(
                          '租金\n包含',
                          style: TextStyle(
                            color: Color(0xFFD1C0C0),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          '水費|電費',
                          style: TextStyle(
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
                      ],
                    )
                  ]),
            ),
            const SizedBox(
              height: 10,
            ),
            Container(
              padding: const EdgeInsets.only(top: 15, bottom: 15, left: 5, right: 5),
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFECD8C9),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.houseDetails['city']}${widget.houseDetails['address']}',
                style: const TextStyle(
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
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.only(left: 15, right: 15),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFECD8C9),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
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
                children:
                    widget.houseDetails['service'].entries.map<Widget>((entry) {
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
            const SizedBox(
              height: 7,
            ),
            const ListTile(
              title: Text(
                '房屋簡介',
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF613F26)),
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Card(
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
                        const CircleAvatar(
                          backgroundImage: NetworkImage(
                              'https://img1.591.com.tw/user/2023/05/09/1683641201851.jpg!100x100.jpg'),
                          radius: 30.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.houseDetails['lessorname'],
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(widget.houseDetails['ownerType'],
                                style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            final Uri url = Uri(
                                scheme: 'tel',
                                path: widget.houseDetails['phone']);

                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              throw '不能撥打 $url';
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF613F26),
                                width: 2.0,
                              ),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Color(0xFF613F26),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.houseDetails['content'],
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
                          style: TextStyle(
                              color: Color.fromRGBO(247, 247, 246, 1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            Stack(
          alignment: Alignment.center,
          children: <Widget>[
            const Divider(
              color: Color(0xFF613F26),
              thickness: 2,
              indent: 20,
              endIndent: 20,
            ),
            Container(
              color: Colors.white, 
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Text('猜您喜歡',style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF613F26)),),
            ),
          ],
        ),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: PageController(viewportFraction: 1),
                itemCount: similarHouses.length,
                itemBuilder: (context, index) {
                  var houseData = similarHouses[index];
                  bool isFavorite = FavoriteManager()
                      .favoriteHids
                      .contains(houseData['hid'].toString());
                  return HouseCard(
                    houseData: houseData,
                    isFavorite: isFavorite,
                    onFavoriteToggle: () =>
                        _toggleFavorite(index, houseData['hid']),
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      int? memberId = prefs.getInt('member_id');

                      if (memberId != null) {
                        await clickrecord(memberId, houseData['hid']);
                      }
                      String hid = houseData['hid'].toString();
                      final response = await http.get(
                        Uri.parse('http://4.227.176.245:5000/houses/$hid'),
                      );

                      if (response.statusCode == 200) {
                        Map<String, dynamic> houseDetails =
                            jsonDecode(response.body);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HouseDetailPage(houseDetails: houseDetails),
                          ),
                        );
                      } else {
                        ('加載失敗');
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('滑動查看更多',style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 137, 136, 136)),),
                SizedBox(width: 4,),
                Icon(Icons.arrow_circle_right_outlined,size: 23,color: Color.fromARGB(255, 137, 136, 136),)
              ],
            ),
            const SizedBox(height: 10,)
             
          ],
        ),
        bottomNavigationBar: GestureDetector(
          onTap: _onBottomAppBarPressed,
          child: const ClipRRect(
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
        ));
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
  const CreateHouseDetailPage({super.key, required this.houseData});
  @override
  State<CreateHouseDetailPage> createState() => _CreateHouseDetailPageState();
}

class _CreateHouseDetailPageState extends State<CreateHouseDetailPage> {
  late Map<String, dynamic> selectedHouse;
  int _current = 0;

  Future<int?> _getMemberId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');
    return memberId;
  }

  void _onBottomAppBarPressed() async {
    int? memberId = await _getMemberId();
    String hid = widget.houseData['hid'].toString();

    if (memberId != null && hid.isNotEmpty) {
      final response = await http.post(
        Uri.parse('http://4.227.176.245:5000/save_click'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'member_id': memberId,
          'hid': hid,
        }),
      );

      if (response.statusCode == 200) {
        String message = "hid:$hid";
        String encodedMessage = Uri.encodeComponent(message);

        final url = Uri.parse(
            "https://line.me/R/oaMessage/%40204wjleq?$encodedMessage");
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        } else {
          ('無法連結 $url');
        }
      } else {
        ('無法連線: ${response.statusCode}');
      }
    } else {
      ('尚未登入或沒有hid');
    }
  }

  @override
  void initState() {
    super.initState();
    selectedHouse = widget.houseData;
    ("houseData: ${widget.houseData}");
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
                widget.houseData['content'],
                style: const TextStyle(fontSize: 20),
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> imageUrlList = List<String>.from(widget.houseData['imageUrl']);
    List<Widget> allImages = imageUrlList
        .map<Widget>((url) => Image.network(url, fit: BoxFit.fill, width: 1000,
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
              return const Image(image: AssetImage('assets/Logo.png'));
            }))
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
                    autoPlayInterval: const Duration(seconds: 4),
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
                  _buildInfoChip('地區', widget.houseData['district']),
                  _buildInfoChip('房屋類型', widget.houseData['houseType']),
                  _buildInfoChip('坪數', widget.houseData['size']),
                  _buildInfoChip('樓層', widget.houseData['floor']),
                  _buildInfoChip('型態', widget.houseData['pattern']),
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
                          widget.houseData['pricecontain'].join('|'),
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
                          '${widget.houseData['price']} 元/月',
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
              padding: const EdgeInsets.only(top: 15, bottom: 15, left: 5, right: 5),
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFECD8C9),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${widget.houseData['city']}${widget.houseData['district']}${widget.houseData['address']}',
                style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF613F26),
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5),
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFECD8C9),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
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
                        style:
                            const TextStyle(fontSize: 18, color: Color(0xFF613F26))),
                    Text('性別限制：${widget.houseData['genderlimit']}',
                        style:
                            const TextStyle(fontSize: 18, color: Color(0xFF613F26))),
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
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.only(left: 15, right: 15),
              padding: const EdgeInsets.all(10),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFECD8C9),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 172, 172, 172).withOpacity(0.5),
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
                children: allservices1.map<Widget>((service) {
                  bool isActive = widget.houseData['service'][service] == true;
                  return Container(
                    width: 80,
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          servicesIcons1[service],
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
            Card(
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
                        const CircleAvatar(
                          backgroundImage: NetworkImage(
                              'https://img1.591.com.tw/user/2023/05/09/1683641201851.jpg!100x100.jpg'),
                          radius: 30.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.houseData['lessorname'],
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            // Text(widget.houseData['ownerType'],
                            //     style: TextStyle(fontSize: 15)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () async {
                            final Uri url = Uri(
                                scheme: 'tel',
                                path: widget.houseData['phone']);

                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            } else {
                              throw '無法撥打 $url';
                            }
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF613F26),
                                width: 2.0,
                              ),
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Color(0xFF613F26),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      widget.houseData['content'],
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
                          style: TextStyle(
                              color: Color.fromRGBO(247, 247, 246, 1)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            )
          ],
        ),
        bottomNavigationBar: GestureDetector(
          onTap: _onBottomAppBarPressed,
          child: const ClipRRect(
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
        ));
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
