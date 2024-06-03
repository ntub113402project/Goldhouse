import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'housedetail_page.dart';

class CreateHousePage extends StatefulWidget {
  @override
  State<CreateHousePage> createState() => _CreateHousePageState();
}

class _CreateHousePageState extends State<CreateHousePage> {
  List<Map<String, dynamic>> createhouses = [];

  void _addHouse(Map<String, dynamic> houseData) {
    setState(() {
      createhouses.add(houseData);
    });
  }

  void _navigateToAddHousePage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPage(onAddHouse: _addHouse),
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
        ),
        body: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF613F26)),
                onPressed: _navigateToAddHousePage,
                child: const Text(
                  '刊登物件',
                  style: TextStyle(color: Color.fromARGB(255, 245, 245, 245)),
                ),
              ),
            ),
            Expanded(
              child: createhouses.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_to_photos_rounded,
                            size: 100,
                            color: Color.fromARGB(255, 181, 181, 181),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            '尚未有刊登物件',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color.fromARGB(255, 181, 181, 181),
                            ),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: createhouses.length,
                      itemBuilder: (context, index) {
                        var house = createhouses[index];
                        var imagePath =
                            house['image'] != null && house['image'].isNotEmpty
                                ? house['image'][0]
                                : 'path/to/default/image.jpg';
                        return Container(
                            width: MediaQuery.of(context).size.width,
                            height: 130,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, top: 10, bottom: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateHouseDetailPage(
                                        houseData: createhouses[index]),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Card(
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
                                          child: Image.file(
                                            File(imagePath),
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
                                                  '${createhouses[index]['roomtype']} | ${createhouses[index]['title']}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.clip,
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${createhouses[index]['size']}坪 ${createhouses[index]['city']}${createhouses[index]['area']}',
                                                  style: const TextStyle(
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
                                          '${createhouses[index]['charge']}',
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
                                ],
                              ),
                            ));
                      },
                    ),
            ),
          ],
        ));
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
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController chargeController = TextEditingController();
  final TextEditingController atfloorController = TextEditingController();
  final TextEditingController allfloorController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController lessornameController = TextEditingController();
  final TextEditingController lessorphoneController = TextEditingController();

  List<XFile>? _imageFileList = [];
  String _selectedCity = '未選擇';
  String? _selectedArea = '未選擇';
  bool _isAreaVisible = false;
  String? _selectedroomtype = '未選擇';
  List<String> _selectedchargecontain = [];
  List<String> _selectedservice = [];
  String? _seletedhousetype = '未選擇';
  String? _selecteddeposit = '未選擇';
  List<String> cities = ['台北市', '新北市', '台中市'];
  Map<String, List<String>> cityDistricts = {
    '台北市': ['中正區', '萬華區', '大同區', '士林區', '大安區'],
    '新北市': ['板橋區', '新店區', '中和區'],
    '台中市': ['北屯區', '西屯區', '南屯區'],
  };
  List<String> roomtype = ['整層住家', '獨立套房', '分租套房', '雅房'];
  List<String> lessortype = ['屋主', '房仲'];
  List<String> chargecontain = ['水費', '電費', '管理費', '停車費'];
  List<String> service = [
    '冰箱',
    '洗衣機',
    '電視',
    '冷氣',
    '熱水器',
    '瓦斯',
    '床',
    '衣櫃',
    '第四台',
    '沙發',
    '桌椅',
    '陽台',
    '電梯',
    '車位',
    '廚房'
  ];
  List<String> housetype = ['別墅', '公寓', '電梯大樓', '透天厝'];
  List<String> deposit = ['免押金', '押金一個月', '押金兩個月'];

  int? _lessortype = 0;
  int? _pet = 0;
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
      print("图片选择失败：$e");
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _imageFileList!.removeAt(index);
    });
  }

  void _submitData() {
    List<String> imagePaths =
        _imageFileList!.map((xFile) => xFile.path).toList();
    Map<String, dynamic> data = {
      'city': _selectedCity,
      'area': _selectedArea ?? '未選擇',
      'title': titleController.text,
      'address': addressController.text,
      'description': descriptionController.text,
      'charge': chargeController.text,
      'chargecontain': _selectedchargecontain,
      'deposit': _selecteddeposit ?? '未選擇',
      'roomtype': _selectedroomtype ?? '未選擇',
      'atfloor': atfloorController.text,
      'allfloor': allfloorController.text,
      'size': sizeController.text,
      'housetype': _seletedhousetype,
      'service': _selectedservice,
      'lessorType': _lessortype == 1 ? '屋主' : '房仲',
      'pet': _pet == 1 ? '可養寵物' : '不可養寵物',
      'genderlimit':
          _genderlimit == 1 ? '限男' : (_genderlimit == 2 ? '限女' : '不限'),
      'lessorname': lessornameController.text,
      'lessorgender': _lessorgender == 1 ? '先生' : '小姐',
      'lessorphone': lessorphoneController.text,
      'image': imagePaths,
    };

    widget.onAddHouse(data);
    Navigator.of(context).pop();
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
                                    .map((area) => ListTile(
                                          title: Text(area),
                                          onTap: () =>
                                              Navigator.pop(context, area),
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
                controller: descriptionController,
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
                controller: chargeController,
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
                List<String>? selectedchargecontain =
                    await showModalBottomSheet<List<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    final selectedTemp =
                        List<String>.from(_selectedchargecontain);
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
                                    children: chargecontain
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

                if (selectedchargecontain != null) {
                  setState(() {
                    _selectedchargecontain = selectedchargecontain;
                  });
                }
              },
                  trailingText: _selectedchargecontain.isNotEmpty
                      ? _selectedchargecontain.join(',')
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
                String? selectedroomtype = await showModalBottomSheet<String>(
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
                        ...roomtype.map((type) => ListTile(
                              title: Text(type),
                              onTap: () => Navigator.pop(context, type),
                            ))
                      ].toList(),
                    );
                  },
                );

                if (selectedroomtype != null) {
                  setState(() {
                    _selectedroomtype = selectedroomtype;
                  });
                }
              }, trailingText: _selectedroomtype),
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
                String? selectedhousetype = await showModalBottomSheet<String>(
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
                        ...housetype.map((type) => ListTile(
                              title: Text(type),
                              onTap: () => Navigator.pop(context, type),
                            ))
                      ].toList(),
                    );
                  },
                );

                if (selectedhousetype != null) {
                  setState(() {
                    _seletedhousetype = selectedhousetype;
                  });
                }
              }, trailingText: _seletedhousetype),
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
                      value: 1,
                      groupValue: _pet,
                      onChanged: _handleRadioValuChangedpet,
                    ),
                    const Text(
                      '可養寵',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 2,
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
                      title: Text('性別限制',
                          style: TextStyle(
                              color: Color(0xFF613F26), fontSize: 20)),
                    )),
                    Radio(
                      value: 1,
                      groupValue: _genderlimit,
                      onChanged: _handleRadioValuChangedgender,
                    ),
                    const Text(
                      '男',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 2,
                      groupValue: _genderlimit,
                      onChanged: _handleRadioValuChangedgender,
                    ),
                    const Text(
                      '女',
                      style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                    ),
                    Radio(
                      value: 3,
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
                    value: 1,
                    groupValue: _lessorgender,
                    onChanged: _handleRadioValuChangedlessorgender,
                  ),
                  const Text(
                    '先生',
                    style: TextStyle(fontSize: 16, color: Color(0xFF613F26)),
                  ),
                  Radio(
                    value: 2,
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
                controller: lessorphoneController,
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
