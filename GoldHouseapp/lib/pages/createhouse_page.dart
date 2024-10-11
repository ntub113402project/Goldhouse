import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'housedetail_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateHousePage extends StatefulWidget {
  @override
  State<CreateHousePage> createState() => _CreateHousePageState();
}

class _CreateHousePageState extends State<CreateHousePage> {
  List<Map<String, dynamic>> createhouses = [];
  int? selectedHouseIndex;
  Map<int, bool> selected = {};
  bool showcheckbox = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHousesFromServer();
  }

  void _fetchHousesFromServer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');

    if (memberId != null) {
      final response = await http.get(
          Uri.parse('http://4.227.176.245:5000/houses_by_member/$memberId'));

      if (response.statusCode == 200) {
        List<dynamic> housesData = json.decode(response.body);

        setState(() {
          createhouses =
              housesData.map((house) => house as Map<String, dynamic>).toList();
          isLoading = false;
        });

        List<String> storedHouses =
            housesData.map((house) => jsonEncode(house)).toList();
        await prefs.setStringList('storedHouses', storedHouses);
      } else {
        setState(() {
          isLoading = false;  
        });
        print('Failed to load houses from server');
      }
    } else {
      setState(() {
        isLoading = false;  
      });
      print('User not logged in');
    }
  }

  void _addHouse(Map<String, dynamic> houseData) async {
    setState(() {
      createhouses.add(houseData);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> storedHouses = prefs.getStringList('storedHouses') ?? [];
    storedHouses.add(jsonEncode(houseData));
    await prefs.setStringList('storedHouses', storedHouses);
  }

  void _deleteHouse(String hid, int index) async {
    final response = await http.delete(
      Uri.parse('http://4.227.176.245:5000/houses/$hid'),
    );

    if (response.statusCode == 200) {
      setState(() {
        createhouses.removeAt(index);
      });

      // 更新 SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> storedHouses = prefs.getStringList('storedHouses') ?? [];
      storedHouses.removeWhere((house) => jsonDecode(house)['hid'] == hid);
      await prefs.setStringList('storedHouses', storedHouses);
    } else {}
  }

  void fetchHouseDetails(BuildContext context, String hid) async {
    final response =
        await http.get(Uri.parse('http://4.227.176.245:5000/houses/$hid'));

    if (response.statusCode == 200) {
      final houseDetails = json.decode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateHouseDetailPage(houseData: houseDetails),
        ),
      );
      _hideOverlay();
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load house details')),
      );
    }
  }

  void _showOverlay(int index) {
    setState(() {
      selectedHouseIndex = index;
    });
  }

  void _hideOverlay() {
    setState(() {
      selectedHouseIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: Image.asset(
          "assets/logo_words.png",
          fit: BoxFit.contain,
          height: 70,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF613F26),
                  ),
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    int? memberId = prefs.getInt('member_id');
                    if (memberId == null) {
                      showDialog(
                        context: context,
                        barrierDismissible: false, 
                        builder: (BuildContext context) {
                          Future.delayed(Duration(seconds: 2), () {
                            Navigator.of(context).pop(); 
                          });

                          return AlertDialog(
                            backgroundColor: Color.fromARGB(255, 40, 40, 40),
                            title: Center(child: Text('請先登入',style: TextStyle(color: const Color.fromARGB(255, 243, 243, 243),fontWeight: FontWeight.bold),)),
                          );
                        },
                      );
                    } else {
                      final houseData = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddPage(onAddHouse: _addHouse),
                        ),
                      );

                      if (houseData != null) {
                        _addHouse(houseData); // 添加新的房屋數據
                        _fetchHousesFromServer(); // 重新從服務器獲取最新的房屋數據
                      }
                    }
                  },
                  child: const Text(
                    '刊登物件',
                    style: TextStyle(color: Color.fromARGB(255, 245, 245, 245)),
                  ),
                ),
              ),
              if(createhouses.isNotEmpty)
              Positioned(
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.delete_forever),
                  onPressed: () {
                    setState(() {
                      showcheckbox = !showcheckbox;
                    });
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF613F26),
                    ), 
                  )
                : createhouses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_to_photos_rounded,
                              size: 100,
                              color: Color.fromARGB(255, 181, 181, 181),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '尚未有刊登物件',
                              style: TextStyle(
                                fontSize: 20,
                                color: Color.fromARGB(255, 181, 181, 181),
                              ),
                            ),
                          ],
                        ),
                      )
                : ListView.builder(
                    itemCount: createhouses.length,
                    itemBuilder: (context, index) {
                      var house = createhouses[index];
                      var imagePath = (house['images'] is List &&
                              house['images'].isNotEmpty)
                          ? house['images'][0]
                          : 'assets/Logo.png';

                      var imageUrl = imagePath.startsWith('http')
                          ? imagePath
                          : 'http://4.227.176.245:5000$imagePath';
                      return Container(
                          width: MediaQuery.of(context).size.width,
                          height: 150,
                          margin: const EdgeInsets.only(
                              left: 20, right: 20, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showOverlay(index),
                                child: Stack(children: [
                                  Card(
                                    color: selectedHouseIndex == index
                                        ? Colors.grey[300]
                                        : Colors.white,
                                    elevation: 0,
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                          ),
                                          child: imageUrl.startsWith('http')
                                              ? Image.network(
                                                  imageUrl,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Image.asset(
                                                      'assets/Logo.png',
                                                      fit: BoxFit.cover,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.35,
                                                      height: double.infinity,
                                                    );
                                                  },
                                                  fit: BoxFit.cover,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.35,
                                                  height: double.infinity,
                                                )
                                              : Image.asset(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.35,
                                                  height: double.infinity,
                                                ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${createhouses[index]['pattern']} | ${createhouses[index]['title']}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.clip,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${createhouses[index]['size']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.clip,
                                                ),
                                                Text(
                                                  '${createhouses[index]['city']} ${createhouses[index]['district']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                )
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
                                          '${createhouses[index]['price']}',
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 249, 58, 58),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Text(
                                          ' 元/月',
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 249, 58, 58),
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (showcheckbox)
                                    Positioned(
                                        top: -5,
                                        right: -5,
                                        child: IconButton(
                                            onPressed: () {
                                              String hid =
                                                  createhouses[index]['hid'];
                                              _deleteHouse(hid, index);
                                              setState(() {
                                                showcheckbox = !showcheckbox;
                                              });
                                            },
                                            icon: Icon(
                                              Icons.cancel_rounded,
                                              color: Color(0xFF613F26),
                                              size: 30,
                                            ))),
                                  if (selectedHouseIndex == index)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onTap: _hideOverlay,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                Color.fromARGB(255, 33, 33, 33)
                                                    .withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  String hid =
                                                      createhouses[index]
                                                          ['hid'];
                                                  fetchHouseDetails(
                                                      context, hid);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: const Text(
                                                  '瀏覽房屋',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final updatedHouseData =
                                                      await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditHousePage(
                                                              houseData:
                                                                  createhouses[
                                                                      index]),
                                                    ),
                                                  );

                                                  if (updatedHouseData !=
                                                      null) {
                                                    // 更新房屋數據
                                                    setState(() {
                                                      createhouses[index] =
                                                          updatedHouseData;
                                                    });

                                                    // 隱藏覆蓋層
                                                    _hideOverlay();

                                                    // 刷新資料列表
                                                    _fetchHousesFromServer(); // 重新從服務器獲取最新的房屋數據
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: const Text(
                                                  '編輯房屋',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ]),
                              ),
                            ],
                          ));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AddPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddHouse;

  const AddPage({Key? key, required this.onAddHouse}) : super(key: key);
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController atfloorController = TextEditingController();
  final TextEditingController allfloorController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController lessornameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  List<XFile>? _imageFileList = [];
  String _selectedCity = '未選擇';
  String? _selectedArea = '未選擇';
  bool _isAreaVisible = false;
  String? _selectedpattern = '未選擇';
  List<String> _selectedpricecontain = [];
  List<String> _selectedservice = [];
  String? _seletedtype = '未選擇';
  String? _selecteddeposit = '未選擇';
  List<String> cities = ['臺北市', '新北市', '台中市'];
  Map<String, List<String>> cityDistricts = {
    '臺北市': ['中正區', '萬華區', '大同區', '士林區', '大安區'],
    '新北市': ['板橋區', '新店區', '中和區'],
    '台中市': ['北屯區', '西屯區', '南屯區'],
  };
  List<String> pattern = ['整層住家', '獨立套房', '分租套房', '雅房'];
  List<String> lessortype = ['屋主', '房仲'];
  List<String> pricecontain = ['水費', '電費', '管理費', '停車費'];
  List<String> service = [
    '冰箱',
    '洗衣機',
    '電視',
    '冷氣',
    '熱水器',
    '床',
    '衣櫃',
    '第四台',
    '網路',
    '天然瓦斯',
    '沙發',
    '桌椅',
    '陽台',
    '電梯',
    '車位',
  ];
  List<String> type = ['別墅', '公寓', '電梯大樓', '透天厝'];
  List<String> deposit = ['免押金', '押金一個月', '押金兩個月'];

  int? _lessortype = 0;
  int? _pet = 0;
  int? _fire = 0;
  int? _genderlimit = 0;
  int? _lessorgender = 0;
  void _handleRadioValuChangedlessortype(int? value) {
    setState(() {
      _lessortype = value ?? 0;
    });
  }

  void _handleRadioValuChangedpet(int? value) {
    setState(() {
      _pet = value ?? 0;
    });
  }

  void _handleRadioValuChangedfire(int? value) {
    setState(() {
      _fire = value ?? 0;
    });
  }

  void _handleRadioValuChangedgender(int? value) {
    setState(() {
      _genderlimit = value ?? 0;
    });
  }

  void _handleRadioValuChangedlessorgender(int? value) {
    setState(() {
      _lessorgender = value ?? 0;
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          _imageFileList!.addAll(pickedFiles);
        });
      }
    } catch (e) {
      print("图片選擇失敗：$e");
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _imageFileList!.removeAt(index);
    });
  }

  void _submitData() async {
    // 提交新增請求
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');

    // 確保用戶已登入
    if (memberId == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text('請先登入'),
            actions: <Widget>[
              TextButton(
                child: const Text('確認'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
      return;
    }

    String layer = '${atfloorController.text}F/${allfloorController.text}F';
    String agency =
        '${lessornameController.text}${_lessorgender == 0 ? '先生' : '小姐'}';

    final uri = Uri.parse('http://4.227.176.245:5000/add_house');
    final request = http.MultipartRequest('POST', uri);

    request.fields['member_id'] = memberId.toString();
    request.fields['city'] = _selectedCity;
    request.fields['district'] = _selectedArea ?? '未選擇';
    request.fields['title'] = titleController.text;
    request.fields['address'] = addressController.text;
    request.fields['content'] = contentController.text;
    request.fields['price'] = priceController.text;
    request.fields['pricecontain'] = jsonEncode(_selectedpricecontain);
    request.fields['deposit'] = _selecteddeposit ?? '未選擇';
    request.fields['pattern'] = _selectedpattern ?? '未選擇';
    request.fields['layer'] = layer;
    request.fields['size'] = sizeController.text;
    request.fields['type'] = _seletedtype ?? '未選擇';
    request.fields['service'] = jsonEncode(_selectedservice);
    request.fields['lessorType'] = _lessortype == 0 ? '屋主' : '房仲';
    request.fields['pet'] = _pet == 0 ? '可' : '不可';
    request.fields['fire'] = _fire == 0 ? '可' : '不可';
    request.fields['genderlimit'] =
        _genderlimit == 0 ? '限男' : (_genderlimit == 1 ? '限女' : '不限');
    request.fields['agency'] = agency;
    request.fields['phone'] = phoneController.text;

    for (var imageFile in _imageFileList!) {
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        imageFile.path,
      ));
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);

        final String? hid = responseData['hid'];
        if (hid == null) {
          print('Failed to retrieve hid from server response');
          return;
        }

        print('House added successfully: $responseBody');

        Map<String, dynamic> houseData = {
          'hid': hid,
          'member_id': memberId,
          'city': _selectedCity,
          'district': _selectedArea,
          'title': titleController.text,
          'address': addressController.text,
          'content': contentController.text,
          'price': priceController.text,
          'pricecontain': _selectedpricecontain,
          'deposit': _selecteddeposit,
          'pattern': _selectedpattern,
          'layer': layer,
          'size': sizeController.text,
          'type': _seletedtype,
          'service': _selectedservice,
          'lessorType': _lessortype == 0 ? '屋主' : '房仲',
          'pet': _pet == 0 ? '可' : '不可',
          'fire': _fire == 0 ? '可' : '不可',
          'genderlimit':
              _genderlimit == 0 ? '限男' : (_genderlimit == 1 ? '限女' : '不限'),
          'agency': agency,
          'phone': phoneController.text,
          'images': _imageFileList!.map((xFile) => xFile.path).toList(),
        };

        Navigator.of(context).pop(houseData); // 返回新增的房屋數據
      } else {
        print('Failed to add house: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during house addition: $e');
    }
  }

  Widget _buildListTile(String titleText, void Function()? onTap,
      {String? trailingText}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          title: Text(titleText,
              style: const TextStyle(color: Color(0xFF613F26), fontSize: 20)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailingText != null && trailingText.length > 10
                    ? '${trailingText.substring(0, 10)}...'
                    : trailingText ?? '',
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFECD8C9),
          title: Image.asset(
            "assets/logo_words.png",
            fit: BoxFit.contain,
            height: 70,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10, bottom: 10),
          child: ListView(
            children: [
              _buildListTile('縣市', () async {
                String? selectedCity = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('選擇縣市',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...cities.map((city) => ListTile(
                              title: Text(city),
                              onTap: () => Navigator.pop(context, city),
                            ))
                      ],
                    );
                  },
                );

                if (selectedCity != null) {
                  setState(() {
                    _selectedCity = selectedCity;
                    _selectedArea = '未選擇';
                    _isAreaVisible = true;
                  });
                }
              }, trailingText: _selectedCity),
              const SizedBox(
                height: 10,
              ),
              if (_isAreaVisible)
                Column(
                  children: [
                    _buildListTile('地區', () async {
                      String? selectedArea = await showModalBottomSheet<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return ListView(
                              padding: EdgeInsets.all(16),
                              children: [
                                const Text('選擇地區',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    )),
                                ...cityDistricts[_selectedCity]!
                                    .map((district) => ListTile(
                                          title: Text(district),
                                          onTap: () =>
                                              Navigator.pop(context, district),
                                        ))
                              ]);
                        },
                      );

                      if (selectedArea != null) {
                        setState(() {
                          _selectedArea = selectedArea;
                        });
                      }
                    }, trailingText: _selectedArea),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '地址',
                  prefixIcon: Icon(Icons.location_pin),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '刊登標題',
                  prefixIcon: Icon(Icons.subtitles_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: contentController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '房屋描述',
                  prefixIcon: Icon(Icons.description_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                maxLines: null,
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  suffixText: '元/月',
                  labelText: '租金',
                  prefixIcon: Icon(Icons.monetization_on),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('租金包含', () async {
                List<String>? selectedpricecontain =
                    await showModalBottomSheet<List<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    final selectedTemp =
                        List<String>.from(_selectedpricecontain);
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('租金包含',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    )),
                                CheckboxListTile(
                                  title: const Text('無'),
                                  value: selectedTemp.isEmpty,
                                  onChanged: (bool? selected) {
                                    setState(() {
                                      if (selected == true) {
                                        selectedTemp.clear();
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: ListView(
                                    children: pricecontain
                                        .map((contain) => CheckboxListTile(
                                              title: Text(contain),
                                              value: selectedTemp
                                                      .contains(contain) &&
                                                  selectedTemp.isNotEmpty,
                                              onChanged: (bool? selected) {
                                                setState(() {
                                                  if (selected == true) {
                                                    selectedTemp.remove('無');
                                                    selectedTemp.add(contain);
                                                  } else {
                                                    selectedTemp
                                                        .remove(contain);
                                                  }
                                                });
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, selectedTemp),
                                  style: const ButtonStyle(
                                      backgroundColor: MaterialStatePropertyAll(
                                          Color(0xFF613F26))),
                                  child: const Text(
                                    '確認',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            ));
                      },
                    );
                  },
                );

                if (selectedpricecontain != null) {
                  setState(() {
                    _selectedpricecontain = selectedpricecontain;
                  });
                }
              },
                  trailingText: _selectedpricecontain.isNotEmpty
                      ? _selectedpricecontain.join(',')
                      : '無'),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('押金', () async {
                String? selecteddeposit = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('押金月數',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...deposit.map((deposit) => ListTile(
                              title: Text(deposit),
                              onTap: () => Navigator.pop(context, deposit),
                            ))
                      ].toList(),
                    );
                  },
                );

                if (selecteddeposit != null) {
                  setState(() {
                    _selecteddeposit = selecteddeposit;
                  });
                }
              }, trailingText: _selecteddeposit),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('房屋類型', () async {
                String? selectedpattern = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('房屋類型',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...pattern.map((pattern) => ListTile(
                              title: Text(pattern),
                              onTap: () => Navigator.pop(context, pattern),
                            ))
                      ].toList(),
                    );
                  },
                );

                if (selectedpattern != null) {
                  setState(() {
                    _selectedpattern = selectedpattern;
                  });
                }
              }, trailingText: _selectedpattern),
              const SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 3,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      const Expanded(
                          child: ListTile(
                        title: Text('樓層',
                            style: TextStyle(
                                color: Color(0xFF613F26), fontSize: 20)),
                      )),
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.only(bottom: 5, top: 5),
                          child: TextFormField(
                            controller: atfloorController,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.create_rounded),
                              labelText: '樓層',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF615AAB),
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 126, 97, 97),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.only(bottom: 5, top: 5, right: 5),
                          child: TextFormField(
                            controller: allfloorController,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.create_rounded),
                              labelText: '總樓層',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF615AAB),
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 126, 97, 97),
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: sizeController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  suffixText: '坪',
                  labelText: '坪數',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('出租人類型',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 1,
                      groupValue: _lessortype,
                      onChanged: _handleRadioValuChangedlessortype,
                    ),
                    const Text(
                      '屋主',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 2,
                      groupValue: _lessortype,
                      onChanged: _handleRadioValuChangedlessortype,
                    ),
                    const Text(
                      '房仲',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildListTile('家具', () async {
                List<String>? selectedservice =
                    await showModalBottomSheet<List<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    final selectedTemp = List<String>.from(_selectedservice);
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('提供家具',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    )),
                                CheckboxListTile(
                                  title: const Text('無'),
                                  value: selectedTemp.isEmpty,
                                  onChanged: (bool? selected) {
                                    setState(() {
                                      if (selected == true) {
                                        selectedTemp.clear();
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: ListView(
                                    children: service
                                        .map((service) => CheckboxListTile(
                                              title: Text(service),
                                              value: selectedTemp
                                                      .contains(service) &&
                                                  selectedTemp.isNotEmpty,
                                              onChanged: (bool? selected) {
                                                setState(() {
                                                  if (selected == true) {
                                                    selectedTemp.remove('無');
                                                    selectedTemp.add(service);
                                                  } else {
                                                    selectedTemp
                                                        .remove(service);
                                                  }
                                                });
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, selectedTemp),
                                  style: const ButtonStyle(
                                      backgroundColor: MaterialStatePropertyAll(
                                          Color(0xFF613F26))),
                                  child: const Text(
                                    '確認',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            ));
                      },
                    );
                  },
                );

                if (selectedservice != null) {
                  setState(() {
                    _selectedservice = selectedservice;
                  });
                }
              },
                  trailingText: _selectedservice.isNotEmpty
                      ? _selectedservice.join(',')
                      : '無'),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('型態', () async {
                String? selectedtype = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('房屋型態',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...type.map((type) => ListTile(
                              title: Text(type),
                              onTap: () => Navigator.pop(context, type),
                            ))
                      ].toList(),
                    );
                  },
                );

                if (selectedtype != null) {
                  setState(() {
                    _seletedtype = selectedtype;
                  });
                }
              }, trailingText: _seletedtype),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('寵物',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 0,
                      groupValue: _pet,
                      onChanged: _handleRadioValuChangedpet,
                    ),
                    const Text(
                      '可養寵',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 1,
                      groupValue: _pet,
                      onChanged: _handleRadioValuChangedpet,
                    ),
                    const Text(
                      '不可養寵',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('開伙',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 0,
                      groupValue: _fire,
                      onChanged: _handleRadioValuChangedfire,
                    ),
                    const Text(
                      '可開伙',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 1,
                      groupValue: _fire,
                      onChanged: _handleRadioValuChangedfire,
                    ),
                    const Text(
                      '不可開伙',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('性別限制',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 0,
                      groupValue: _genderlimit,
                      onChanged: _handleRadioValuChangedgender,
                    ),
                    const Text(
                      '男',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 1,
                      groupValue: _genderlimit,
                      onChanged: _handleRadioValuChangedgender,
                    ),
                    const Text(
                      '女',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 2,
                      groupValue: _genderlimit,
                      onChanged: _handleRadioValuChangedgender,
                    ),
                    const Text(
                      '不限',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: lessornameController,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.create_rounded),
                        labelText: '刊登者姓氏',
                        prefixIcon: Icon(Icons.face_rounded),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF615AAB),
                            width: 3,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 126, 97, 97),
                            width: 3,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Radio(
                    value: 0,
                    groupValue: _lessorgender,
                    onChanged: _handleRadioValuChangedlessorgender,
                  ),
                  const Text(
                    '先生',
                    style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                  ),
                  Radio(
                    value: 1,
                    groupValue: _lessorgender,
                    onChanged: _handleRadioValuChangedlessorgender,
                  ),
                  const Text(
                    '小姐',
                    style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '連絡電話',
                  prefixIcon: Icon(Icons.local_phone_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 3,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              child: ListTile(
                            title: Text('新增房屋照片',
                                style: TextStyle(
                                    color: Color(0xFF613F26), fontSize: 20)),
                          )),
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 30,
                          ),
                          SizedBox(
                            width: 8,
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: _imageFileList!.isEmpty ? 200.0 : null,
                    margin: EdgeInsets.only(left: 20, right: 20),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _imageFileList!.isEmpty
                        ? Center(
                            child: Text(
                              '尚未新增房屋照片',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 25, color: Color(0xFFC7ADAD)),
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4.0,
                              mainAxisSpacing: 4.0,
                            ),
                            itemCount: _imageFileList!.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Stack(
                                children: [
                                  Image.file(
                                    File(_imageFileList![index].path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                  Positioned(
                                    top: -5,
                                    right: -5,
                                    child: IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        _deleteImage(index);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Color(0xFF613F26))),
                      child: const Text('刊登',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  )
                ],
              ),
            ],
          ),
        ));
  }
}

class EditHousePage extends StatefulWidget {
  final Map<String, dynamic> houseData;

  const EditHousePage({Key? key, required this.houseData}) : super(key: key);

  @override
  _EditHousePageState createState() => _EditHousePageState();
}

class _EditHousePageState extends State<EditHousePage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController atfloorController = TextEditingController();
  final TextEditingController allfloorController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController lessornameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  List<dynamic> _imageFileList = [];
  String? _selectedCity;
  String? _selectedArea;
  bool _isAreaVisible = false;
  String? _selectedpattern;
  List<String> _selectedpricecontain = [];
  List<String> _selectedservice = [];
  String? _seletedtype;
  String? _selecteddeposit;
  int? _lessortype;
  int? _pet;
  int? _fire;
  int? _genderlimit;
  int? _lessorgender;
  final Map<String, dynamic> _changedFields = {};

  @override
  void initState() {
    super.initState();

    addressController.text = widget.houseData['address'];
    titleController.text = widget.houseData['title'];
    contentController.text = widget.houseData['content'];
    priceController.text = widget.houseData['price'].toString();
    List<String> layer = widget.houseData['layer'].split('/');
    atfloorController.text =
        layer.isNotEmpty ? layer[0].replaceAll('F', '') : '';
    allfloorController.text =
        layer.length > 1 ? layer[1].replaceAll('F', '') : '';
    sizeController.text = widget.houseData['size'].replaceAll('坪', '');
    phoneController.text = widget.houseData['phone'];
    String agency = widget.houseData['agency'];
    lessornameController.text = agency.substring(0, agency.length - 2);
    _lessorgender = agency.endsWith('先生') ? 0 : 1;

    _selectedCity = widget.houseData['city'];
    _selectedArea = widget.houseData['district'];
    _isAreaVisible = _selectedArea != null;
    _selectedpattern = widget.houseData['pattern'];
    _selectedpricecontain = widget.houseData['pricecontain'] is String
        ? [widget.houseData['pricecontain']]
        : List<String>.from(widget.houseData['pricecontain']);

    _selectedservice = widget.houseData['service'] is String
        ? [widget.houseData['service']]
        : List<String>.from(widget.houseData['service']);
    _seletedtype = widget.houseData['type'];
    _selecteddeposit = widget.houseData['deposit'];
    _lessortype = widget.houseData['lessorType'] == '屋主' ? 0 : 1;
    _pet = widget.houseData['pet'] == '可' ? 0 : 1;
    _fire = widget.houseData['fire'] == '可' ? 0 : 1;
    _genderlimit = widget.houseData['genderlimit'] == '限男'
        ? 0
        : (widget.houseData['genderlimit'] == '限女' ? 1 : 2);
    _imageFileList = widget.houseData['images']
        .map<String>((path) => path is String && path.startsWith('http')
            ? path
            : 'http://4.227.176.245:5000' + (path as String))
        .toList();
  }

  void _onFieldChanged(String field, dynamic value) {
    _changedFields[field] = value;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null) {
        setState(() {
          _imageFileList.addAll(pickedFiles.map<String>((xFile) => xFile.path));
        });

        _onFieldChanged('images', _imageFileList);
      }
    } catch (e) {
      print("圖片選擇失敗：$e");
    }
  }

  List<String> _imagesToDelete = [];

  void _deleteImage(int index) async {
    final imageToDelete = _imageFileList[index];

    if (imageToDelete is String) {
      _imagesToDelete.add(imageToDelete);
    }

    setState(() {
      _imageFileList.removeAt(index);
    });

    _onFieldChanged(
      'images',
      _imageFileList
          .map((image) => image is String ? image : (image as XFile).path)
          .toList(),
    );
  }

  void _submitData() async {
    final uri = Uri.parse('http://4.227.176.245:5000/edit_house');
    final request = http.MultipartRequest('POST', uri);

    _changedFields['layer'] =
        '${atfloorController.text}F/${allfloorController.text}F';
    _changedFields['agency'] =
        '${lessornameController.text}${_lessorgender == 0 ? '先生' : '小姐'}';

    request.fields['hid'] = widget.houseData['hid'];

    _changedFields.forEach((key, value) {
      if (key != 'images') {
        if (key == 'pricecontain' || key == 'service') {
          request.fields[key] = value.join(',');
        } else {
          request.fields[key] = value.toString();
        }
      }
    });

    for (var imageFile in _imageFileList) {
      if (imageFile is String && !imageFile.startsWith('http')) {
        request.files.add(await http.MultipartFile.fromPath(
          'images',
          imageFile,
        ));
      }
    }

    if (_imagesToDelete.isNotEmpty) {
      request.fields['images_to_delete'] = json.encode(_imagesToDelete);
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final updatedHouseData = {...widget.houseData, ..._changedFields};
      Navigator.of(context).pop(updatedHouseData);
    } else {
      print('Failed to edit house: ${response.statusCode}');
    }
  }

  Widget _buildListTile(String titleText, void Function()? onTap,
      {String? trailingText}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 3,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          title: Text(titleText,
              style: const TextStyle(color: Color(0xFF613F26), fontSize: 20)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trailingText != null && trailingText.length > 10
                    ? '${trailingText.substring(0, 10)}...'
                    : trailingText ?? '',
                style: const TextStyle(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFECD8C9),
          title: Image.asset(
            "assets/logo_words.png",
            fit: BoxFit.contain,
            height: 70,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(right: 10, left: 10, bottom: 10),
          child: ListView(
            children: [
              _buildListTile('縣市', () async {
                String? selectedCity = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('選擇縣市',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...['臺北市', '新北市', '台中市'].map((city) => ListTile(
                              title: Text(city),
                              onTap: () => Navigator.pop(context, city),
                            ))
                      ],
                    );
                  },
                );

                if (selectedCity != null) {
                  setState(() {
                    _selectedCity = selectedCity;
                    _onFieldChanged('city', _selectedCity);
                    _selectedArea = '未選擇';
                    _isAreaVisible = true;
                  });
                }
              }, trailingText: _selectedCity),
              const SizedBox(
                height: 10,
              ),
              if (_isAreaVisible)
                Column(
                  children: [
                    _buildListTile('地區', () async {
                      String? selectedArea = await showModalBottomSheet<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return ListView(
                              padding: EdgeInsets.all(16),
                              children: [
                                const Text('選擇地區',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    )),
                                ...{
                                  '臺北市': ['中正區', '萬華區', '大同區', '士林區', '大安區'],
                                  '新北市': ['板橋區', '新店區', '中和區'],
                                  '台中市': ['北屯區', '西屯區', '南屯區'],
                                }[_selectedCity]!
                                    .map((district) => ListTile(
                                          title: Text(district),
                                          onTap: () =>
                                              Navigator.pop(context, district),
                                        ))
                              ]);
                        },
                      );

                      if (selectedArea != null) {
                        setState(() {
                          _selectedArea = selectedArea;
                          _onFieldChanged('district', _selectedArea);
                        });
                      }
                    }, trailingText: _selectedArea),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '地址',
                  prefixIcon: Icon(Icons.location_pin),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  _onFieldChanged('address', value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '刊登標題',
                  prefixIcon: Icon(Icons.subtitles_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  _onFieldChanged('title', value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: contentController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '房屋描述',
                  prefixIcon: Icon(Icons.description_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                maxLines: null,
                onChanged: (value) {
                  _onFieldChanged('content', value);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  suffixText: '元/月',
                  labelText: '租金',
                  prefixIcon: Icon(Icons.monetization_on),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  _onFieldChanged('price', int.tryParse(value) ?? 0);
                },
              ),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('租金包含', () async {
                List<String>? selectedpricecontain =
                    await showModalBottomSheet<List<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    final selectedTemp =
                        List<String>.from(_selectedpricecontain);
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('租金包含',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    )),
                                CheckboxListTile(
                                  title: const Text('無'),
                                  value: selectedTemp.isEmpty,
                                  onChanged: (bool? selected) {
                                    setState(() {
                                      if (selected == true) {
                                        selectedTemp.clear();
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: ListView(
                                    children: ['水費', '電費', '管理費', '停車費']
                                        .map((contain) => CheckboxListTile(
                                              title: Text(contain),
                                              value: selectedTemp
                                                      .contains(contain) &&
                                                  selectedTemp.isNotEmpty,
                                              onChanged: (bool? selected) {
                                                setState(() {
                                                  if (selected == true) {
                                                    selectedTemp.remove('無');
                                                    selectedTemp.add(contain);
                                                  } else {
                                                    selectedTemp
                                                        .remove(contain);
                                                  }
                                                });
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, selectedTemp),
                                  style: const ButtonStyle(
                                      backgroundColor: MaterialStatePropertyAll(
                                          Color(0xFF613F26))),
                                  child: const Text(
                                    '確認',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            ));
                      },
                    );
                  },
                );

                if (selectedpricecontain != null) {
                  setState(() {
                    _selectedpricecontain = selectedpricecontain;
                    _onFieldChanged('pricecontain', _selectedpricecontain);
                  });
                }
              },
                  trailingText: _selectedpricecontain.isNotEmpty
                      ? _selectedpricecontain.join(',')
                      : '無'),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('押金', () async {
                String? selecteddeposit = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('押金月數',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...['免押金', '押金一個月', '押金兩個月'].map((deposit) => ListTile(
                              title: Text(deposit),
                              onTap: () => Navigator.pop(context, deposit),
                            ))
                      ].toList(),
                    );
                  },
                );

                if (selecteddeposit != null) {
                  setState(() {
                    _selecteddeposit = selecteddeposit;
                    _onFieldChanged('deposit', _selecteddeposit);
                  });
                }
              }, trailingText: _selecteddeposit),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('房屋類型', () async {
                String? selectedpattern = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('房屋類型',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...['整層住家', '獨立套房', '分租套房', '雅房']
                            .map((pattern) => ListTile(
                                  title: Text(pattern),
                                  onTap: () => Navigator.pop(context, pattern),
                                ))
                      ].toList(),
                    );
                  },
                );

                if (selectedpattern != null) {
                  setState(() {
                    _selectedpattern = selectedpattern;
                    _onFieldChanged('pattern', _selectedpattern);
                  });
                }
              }, trailingText: _selectedpattern),
              const SizedBox(
                height: 10,
              ),
              Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 3,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      const Expanded(
                          child: ListTile(
                        title: Text('樓層',
                            style: TextStyle(
                                color: Color(0xFF613F26), fontSize: 20)),
                      )),
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.only(bottom: 5, top: 5),
                          child: TextFormField(
                            controller: atfloorController,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.create_rounded),
                              labelText: '樓層',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF615AAB),
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 126, 97, 97),
                                  width: 3,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              _onFieldChanged('atfloor', value);
                            },
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: EdgeInsets.only(bottom: 5, top: 5, right: 5),
                          child: TextFormField(
                            controller: allfloorController,
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.create_rounded),
                              labelText: '總樓層',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF615AAB),
                                  width: 3,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 126, 97, 97),
                                  width: 3,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              _onFieldChanged('allfloor', value);
                            },
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: sizeController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  suffixText: '坪',
                  labelText: '坪數',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  _onFieldChanged('size', value);
                },
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('出租人類型',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 0,
                      groupValue: _lessortype,
                      onChanged: (value) {
                        setState(() {
                          _lessortype = value as int;
                          _onFieldChanged(
                              'lessorType', _lessortype == 0 ? '屋主' : '房仲');
                        });
                      },
                    ),
                    const Text(
                      '屋主',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 1,
                      groupValue: _lessortype,
                      onChanged: (value) {
                        setState(() {
                          _lessortype = value as int;
                          _onFieldChanged(
                              'lessorType', _lessortype == 0 ? '屋主' : '房仲');
                        });
                      },
                    ),
                    const Text(
                      '房仲',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildListTile('家具', () async {
                List<String>? selectedservice =
                    await showModalBottomSheet<List<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    final selectedTemp = List<String>.from(_selectedservice);
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('提供家具',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    )),
                                CheckboxListTile(
                                  title: const Text('無'),
                                  value: selectedTemp.isEmpty,
                                  onChanged: (bool? selected) {
                                    setState(() {
                                      if (selected == true) {
                                        selectedTemp.clear();
                                      }
                                    });
                                  },
                                ),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      '冰箱',
                                      '洗衣機',
                                      '電視',
                                      '冷氣',
                                      '熱水器',
                                      '床',
                                      '衣櫃',
                                      '第四台',
                                      '網路',
                                      '天然瓦斯',
                                      '沙發',
                                      '桌椅',
                                      '陽台',
                                      '電梯',
                                      '車位',
                                    ]
                                        .map((service) => CheckboxListTile(
                                              title: Text(service),
                                              value: selectedTemp
                                                      .contains(service) &&
                                                  selectedTemp.isNotEmpty,
                                              onChanged: (bool? selected) {
                                                setState(() {
                                                  if (selected == true) {
                                                    selectedTemp.remove('無');
                                                    selectedTemp.add(service);
                                                  } else {
                                                    selectedTemp
                                                        .remove(service);
                                                  }
                                                });
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(context, selectedTemp),
                                  style: const ButtonStyle(
                                      backgroundColor: MaterialStatePropertyAll(
                                          Color(0xFF613F26))),
                                  child: const Text(
                                    '確認',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                )
                              ],
                            ));
                      },
                    );
                  },
                );

                if (selectedservice != null) {
                  setState(() {
                    _selectedservice = selectedservice;
                    _onFieldChanged('service', _selectedservice);
                  });
                }
              },
                  trailingText: _selectedservice.isNotEmpty
                      ? _selectedservice.join(',')
                      : '無'),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('型態', () async {
                String? selectedtype = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('房屋型態',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            )),
                        ...['別墅', '公寓', '電梯大樓', '透天厝'].map((type) => ListTile(
                              title: Text(type),
                              onTap: () => Navigator.pop(context, type),
                            ))
                      ].toList(),
                    );
                  },
                );

                if (selectedtype != null) {
                  setState(() {
                    _seletedtype = selectedtype;
                    _onFieldChanged('type', _seletedtype);
                  });
                }
              }, trailingText: _seletedtype),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('寵物',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 0,
                      groupValue: _pet,
                      onChanged: (value) {
                        setState(() {
                          _pet = value as int;
                          _onFieldChanged('pet', _pet == 0 ? '可' : '不可');
                        });
                      },
                    ),
                    const Text(
                      '可養寵',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 1,
                      groupValue: _pet,
                      onChanged: (value) {
                        setState(() {
                          _pet = value as int;
                          _onFieldChanged('pet', _pet == 0 ? '可' : '不可');
                        });
                      },
                    ),
                    const Text(
                      '不可養寵',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('開伙',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 0,
                      groupValue: _fire,
                      onChanged: (value) {
                        setState(() {
                          _fire = value as int;
                          _onFieldChanged('fire', _fire == 0 ? '可' : '不可');
                        });
                      },
                    ),
                    const Text(
                      '可開伙',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 1,
                      groupValue: _fire,
                      onChanged: (value) {
                        setState(() {
                          _fire = value as int;
                          _onFieldChanged('fire', _fire == 0 ? '可' : '不可');
                        });
                      },
                    ),
                    const Text(
                      '不可開伙',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      blurRadius: 3,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                        child: ListTile(
                      title: Text('性別限制',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 0,
                      groupValue: _genderlimit,
                      onChanged: (value) {
                        setState(() {
                          _genderlimit = value as int;
                          _onFieldChanged(
                              'genderlimit',
                              _genderlimit == 0
                                  ? '限男'
                                  : (_genderlimit == 1 ? '限女' : '不限'));
                        });
                      },
                    ),
                    const Text(
                      '男',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 1,
                      groupValue: _genderlimit,
                      onChanged: (value) {
                        setState(() {
                          _genderlimit = value as int;
                          _onFieldChanged(
                              'genderlimit',
                              _genderlimit == 0
                                  ? '限男'
                                  : (_genderlimit == 1 ? '限女' : '不限'));
                        });
                      },
                    ),
                    const Text(
                      '女',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 2,
                      groupValue: _genderlimit,
                      onChanged: (value) {
                        setState(() {
                          _genderlimit = value as int;
                          _onFieldChanged(
                              'genderlimit',
                              _genderlimit == 0
                                  ? '限男'
                                  : (_genderlimit == 1 ? '限女' : '不限'));
                        });
                      },
                    ),
                    const Text(
                      '不限',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    const SizedBox(
                      width: 7,
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: lessornameController,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.create_rounded),
                        labelText: '刊登者姓氏',
                        prefixIcon: Icon(Icons.face_rounded),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF615AAB),
                            width: 3,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color.fromARGB(255, 126, 97, 97),
                            width: 3,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        _onFieldChanged('lessorname', value);
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Radio(
                    value: 0,
                    groupValue: _lessorgender,
                    onChanged: (value) {
                      setState(() {
                        _lessorgender = value as int;
                        _onFieldChanged(
                            'lessorgender', _lessorgender == 0 ? '先生' : '小姐');
                      });
                    },
                  ),
                  const Text(
                    '先生',
                    style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                  ),
                  Radio(
                    value: 1,
                    groupValue: _lessorgender,
                    onChanged: (value) {
                      setState(() {
                        _lessorgender = value as int;
                        _onFieldChanged(
                            'lessorgender', _lessorgender == 0 ? '先生' : '小姐');
                      });
                    },
                  ),
                  const Text(
                    '小姐',
                    style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '連絡電話',
                  prefixIcon: Icon(Icons.local_phone_rounded),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF615AAB),
                      width: 3,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 126, 97, 97),
                      width: 3,
                    ),
                  ),
                ),
                onChanged: (value) {
                  _onFieldChanged('phone', value);
                },
              ),
              SizedBox(
                height: 10,
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 3,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                              child: ListTile(
                            title: Text('新增房屋照片',
                                style: TextStyle(
                                    color: Color(0xFF613F26), fontSize: 20)),
                          )),
                          Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 30,
                          ),
                          SizedBox(
                            width: 8,
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                      height: _imageFileList.isEmpty ? 200.0 : null,
                      margin: EdgeInsets.only(left: 20, right: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _imageFileList.isEmpty
                          ? Center(
                              child: Text(
                                '尚未新增房屋照片',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 25, color: Color(0xFFC7ADAD)),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 4.0,
                                mainAxisSpacing: 4.0,
                              ),
                              itemCount: _imageFileList.length,
                              itemBuilder: (BuildContext context, int index) {
                                final image = _imageFileList[index];
                                return Stack(
                                  children: [
                                    image is String && image.startsWith('http')
                                        ? Image.network(
                                            image,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Image.file(
                                            File(image is XFile
                                                ? image.path
                                                : image),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                    Positioned(
                                      top: -5,
                                      right: -5,
                                      child: IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          _deleteImage(index);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )),
                  SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Color(0xFF613F26))),
                      child: const Text('更新',
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  )
                ],
              ),
            ],
          ),
        ));
  }
}
