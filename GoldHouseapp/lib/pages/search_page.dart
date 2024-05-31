import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFECD8C9),
          title: Image.asset(
            "assets/logo_words.png",
            fit: BoxFit.contain,
            height: 70,
          ),
          centerTitle: true,
        ),
        body: Column(children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 20, right: 60, left: 60, bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                height: 45,
                decoration: BoxDecoration(
                    color: const Color(0xFFECD8C9),
                    borderRadius: BorderRadius.circular(25)),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: const Color.fromARGB(255, 245, 245, 245),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF613F26),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontSize: 20),
                  tabs: [
                    Tab(text: '地區'),
                    Tab(text: '捷運'),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                AreaSearchPage(),
                MRTSearchPage(),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class SearchResultPage extends StatelessWidget {
  final List<dynamic> searchResults;

  // SearchResultPage({Key? key, required this.searchResults}) : super(key: key);
  const SearchResultPage({super.key, required this.searchResults});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜尋結果'),
        backgroundColor: const Color(0xFFECD8C9),
      ),
      body: ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          var result = searchResults[index];
          return Container(
            width: MediaQuery.of(context).size.width,
            height: 130,
            margin:
                const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
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
              onTap: () {Navigator.pushNamed(context, '/housedetail');},
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
                        const ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          // child: Image.network(
                          //   result['imageUrl'],
                          //   fit: BoxFit.cover,
                          //   width: MediaQuery.of(context).size.width * 0.35,
                          //   height: double.infinity,
                          // ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${result['pattern']} | ${result['title']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${result['size']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${result['address']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                    child: Text(
                      '${result['price']}元/月',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 249, 58, 58),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AreaSearchPage extends StatefulWidget {
  @override
  State<AreaSearchPage> createState() => _AreaSearchPageState();
}

class _AreaSearchPageState extends State<AreaSearchPage> {
  String _selectedCity = ' ';
  String _selectedDistrict = '不限';
  String _selectedRoomType = '不限';
  String _selectedRentalRange = '不限';
  String _selectedRoomCount = '不限';
  String _selectedHouseSize = '不限';
  String _selectedHouseType = '不限';
  List<String> _selectedOtherOptions = [];
  Future<void> _search(BuildContext context) async {
    try {
      //資料預處理
      String rentalRange =
          _selectedRentalRange == '不限' ? '' : _selectedRentalRange;
      String houseSize = _selectedHouseSize == '不限' ? '' : _selectedHouseSize;

      // 租金資料處理
      List<int>? rentalRangeList;
      if (rentalRange.contains('以下')) {
        int maxSize = int.tryParse(
                rentalRange.replaceAll('元以下', '').replaceAll(',', '').trim()) ??
            0;
        rentalRangeList = [-1, maxSize];
      } else if (rentalRange.contains('以上')) {
        int minSize = int.tryParse(
                rentalRange.replaceAll('元以上', '').replaceAll(',', '').trim()) ??
            0;
        rentalRangeList = [minSize, -1];
      } else if (rentalRange.contains('－')) {
        List<String> rentParts = rentalRange.replaceAll('元', '').split('－');
        if (rentParts.length == 2) {
          rentalRangeList = [
            int.tryParse(rentParts[0].replaceAll(',', '').trim()) ?? 0,
            int.tryParse(rentParts[1].replaceAll(',', '').trim()) ?? 0
          ];
        }
      }

      // 坪數資料處理
      List<int>? houseSizeList;
      if (houseSize.contains('以下')) {
        int maxSize = int.tryParse(houseSize.replaceAll('坪以下', '').trim()) ?? 0;
        houseSizeList = [-1, maxSize];
      } else if (houseSize.contains('以上')) {
        int minSize = int.tryParse(houseSize.replaceAll('坪以上', '').trim()) ?? 0;
        houseSizeList = [minSize, -1];
      } else if (houseSize.contains('－')) {
        List<String> sizeParts = houseSize.split('－');
        if (sizeParts.length == 2) {
          houseSizeList = [
            int.tryParse(sizeParts[0].replaceAll('坪', '').trim()) ?? 0,
            int.tryParse(sizeParts[1].replaceAll('坪', '').trim()) ?? 0
          ];
        }
      }

      final response = await http.post(
        Uri.parse('http://4.227.176.245:5000/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'city': _selectedCity == '不限' ? null : _selectedCity,
          'district': _selectedDistrict == '不限' ? null : _selectedDistrict,
          'room_type': _selectedRoomType == '不限' ? null : _selectedRoomType,
          'rental_range': rentalRangeList == null ? null : rentalRangeList,
          'room_count': _selectedRoomCount == '不限'
              ? null
              : int.tryParse(_selectedRoomCount.replaceAll('房', '').trim()) ??
                  4,
          'house_size': houseSizeList == null ? null : houseSizeList,
          'house_type': _selectedHouseType == '不限' ? null : _selectedHouseType,
          'other_options': _selectedOtherOptions.join(',')
        }),
      );
      if (response.statusCode == 200) {
        List<dynamic> results = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultPage(searchResults: results),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('搜尋失敗，請稍後再試')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法連線至伺服器或系統維護中')),
      );
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
              Text(trailingText ?? '', style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentSelection,
    required Function(String) onSelectionConfirmed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        String selectedOption = currentSelection;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                for (String option in options)
                  RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: selectedOption,
                    onChanged: (String? value) {
                      setModalState(() {
                        selectedOption = value!;
                      });
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () {
                      onSelectionConfirmed(selectedOption);
                      Navigator.pop(context);
                    },
                    child: const Text('確認'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _roomTypeBottomSheet(BuildContext context) {
    List<String> roomTypes = ['不限', '雅房', '整層住家', '獨立套房', '分租套房'];
    _showSelectionBottomSheet(
      context: context,
      title: '房屋類型',
      options: roomTypes,
      currentSelection: _selectedRoomType,
      onSelectionConfirmed: (String selectedroomtype) {
        setState(() {
          _selectedRoomType = selectedroomtype;
        });
      },
    );
  }

  void _rentalBottomSheet(BuildContext context) {
    List<String> rentalRange = [
      '不限',
      '0－5,000元',
      '5,000－10,000元',
      '10,000－15,000元',
      '15,000－20,000元',
      '20,000－30,000元',
      '30,000－40,000元',
      '40,000元以上'
    ];

    TextEditingController minController = TextEditingController();
    TextEditingController maxController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Center(
                      child: Text(
                        '租金範圍',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  ...rentalRange.map((range) {
                    return ListTile(
                      title: Text(range),
                      onTap: () {
                        Navigator.pop(context, range);
                      },
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: '最低金額',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('－'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: '最高金額',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      String min = minController.text;
                      String max = maxController.text;
                      if (min.isEmpty && max.isNotEmpty) {
                        String customRange = '$max元以下';
                        Navigator.pop(context, customRange);
                      } else if (min.isNotEmpty && max.isEmpty) {
                        String customRange = '$min元以上';
                        Navigator.pop(context, customRange);
                      } else if (min.isNotEmpty && max.isNotEmpty) {
                        int minVal = int.parse(min);
                        int maxVal = int.parse(max);
                        if (minVal >= maxVal) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('輸入錯誤'),
                                content: const Text('最高金額必需大於最低金額'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('確認'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          String customRange = '$min元－$max元';
                          Navigator.pop(context, customRange);
                        }
                      }
                    },
                    child: const Text('確認'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    ).then((selectedRange) {
      if (selectedRange != null) {
        setState(() {
          _selectedRentalRange = selectedRange;
        });
      }
    });
  }

  void _roomCountBottomSheet(BuildContext context) {
    List<String> roomcount = ['不限', '1房', '2房', '3房', '4房以上'];
    _showSelectionBottomSheet(
      context: context,
      title: '格局',
      options: roomcount,
      currentSelection: _selectedRoomCount,
      onSelectionConfirmed: (String selectedCount) {
        setState(() {
          _selectedRoomCount = selectedCount;
        });
      },
    );
  }

  void _houseSizeBottomSheet(BuildContext context) {
    List<String> housesize = [
      '不限',
      '10坪以下',
      '10－20坪',
      '20－30坪',
      '30－40坪',
      '40－50坪',
      '50坪以上'
    ];
    _showSelectionBottomSheet(
      context: context,
      title: '坪數',
      options: housesize,
      currentSelection: _selectedHouseSize,
      onSelectionConfirmed: (String selectedSize) {
        setState(() {
          _selectedHouseSize = selectedSize;
        });
      },
    );
  }

  void _houseTypeBottomSheet(BuildContext context) {
    List<String> houseTypes = ['不限', '別墅', '公寓', '電梯大樓', '透天厝'];
    _showSelectionBottomSheet(
      context: context,
      title: '房屋型態',
      options: houseTypes,
      currentSelection: _selectedHouseType,
      onSelectionConfirmed: (String selectedType) {
        setState(() {
          _selectedHouseType = selectedType;
        });
      },
    );
  }

  void _otherSelectionBottomSheet(BuildContext context) {
    List<String> options = ['不限', '有陽台', '可養寵物', '可開伙'];
    List<String> selectedOptions = ['不限'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '其他條件',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (String option in options)
                    CheckboxListTile(
                      title: Text(option),
                      value: selectedOptions.contains(option),
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (option == '不限') {
                            if (value == true) {
                              selectedOptions.clear();
                              selectedOptions.add(option);
                            } else {
                              selectedOptions.remove(option);
                            }
                          } else {
                            if (value == true) {
                              selectedOptions.remove('不限');
                              selectedOptions.add(option);
                            } else {
                              selectedOptions.remove(option);
                            }
                          }
                        });
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedOtherOptions = List.from(selectedOptions);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('確認'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            _buildListTile(
              '縣市',
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CityPage()),
                );
                if (result != null) {
                  setState(() {
                    _selectedCity = result['city'];
                    _selectedDistrict = result['district'];
                  });
                }
              },
              trailingText: '$_selectedCity $_selectedDistrict',
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '房屋類型',
              () {
                _roomTypeBottomSheet(context);
              },
              trailingText: _selectedRoomType,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '租金',
              () {
                _rentalBottomSheet(context);
              },
              trailingText: _selectedRentalRange,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '格局',
              () {
                _roomCountBottomSheet(context);
              },
              trailingText: _selectedRoomCount,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '坪數',
              () {
                _houseSizeBottomSheet(context);
              },
              trailingText: _selectedHouseSize,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '房屋型態',
              () {
                _houseTypeBottomSheet(context);
              },
              trailingText: _selectedHouseType,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '其他',
              () {
                _otherSelectionBottomSheet(context);
              },
              trailingText: _selectedOtherOptions.isNotEmpty
                  ? _selectedOtherOptions.join(', ')
                  : '不限',
            ),
            const SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  _search(context);
                },
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll(Color(0xFF613F26))),
                child: const Text('搜尋',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}

class CityPage extends StatelessWidget {
  final List<String> cities = [
    '台北市',
    '新北市',
    '基隆市',
    '宜蘭縣',
    '桃園市',
    '新竹市',
    '新竹縣',
    '新竹市',
    '高雄市',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: const Text(
          '縣市',
          style: TextStyle(
              color: Color(0xFF613F26),
              fontWeight: FontWeight.bold,
              fontSize: 25),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
                title: Text(
                  cities[index],
                  style: const TextStyle(
                    color: Color.fromARGB(255, 46, 46, 46),
                    fontSize: 18,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DistrictPage(city: cities[index]),
                    ),
                  ).then((result) {
                    if (result != null) {
                      Navigator.pop(context, result);
                    }
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10, left: 10),
                child: Divider(
                  height: 5,
                  color: Color.fromARGB(255, 221, 221, 221),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class DistrictPage extends StatefulWidget {
  final String city;

  DistrictPage({Key? key, required this.city}) : super(key: key);

  @override
  State<DistrictPage> createState() => _DistrictPageState();
}

class _DistrictPageState extends State<DistrictPage> {
  final Map<String, List<String>> cityDistricts = {
    '台北市': ['不限', '中正區', '萬華區', '中山區', '大同區', '士林區'],
    '新北市': ['不限', '板橋區', '中和區', '永和區'],
    '高雄市': ['不限', '三民區', '鼓山區', '苓雅區'],
  };
  String? _selectedDistrict;

  @override
  Widget build(BuildContext context) {
    final districts = cityDistricts[widget.city] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: Text(
          widget.city,
          style: const TextStyle(
              color: Color(0xFF613F26),
              fontWeight: FontWeight.bold,
              fontSize: 25),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
                onTap: () {
                  if (_selectedDistrict != null) {
                    Navigator.pop(context,
                        {'city': widget.city, 'district': _selectedDistrict});
                  }
                },
                child: const Text(
                  '確認',
                  style: TextStyle(color: Color(0xFF613F26), fontSize: 18),
                )),
          )
        ],
      ),
      body: ListView.builder(
        itemCount: districts.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
                title: Text(districts[index],
                    style: const TextStyle(
                      color: Color.fromARGB(255, 46, 46, 46),
                      fontSize: 18,
                    )),
                trailing: _selectedDistrict == districts[index]
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedDistrict = districts[index];
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10, left: 10),
                child: Divider(
                  height: 5,
                  color: Color.fromARGB(255, 221, 221, 221),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class MRTSearchPage extends StatefulWidget {
  @override
  State<MRTSearchPage> createState() => _MRTSearchPageState();
}

class _MRTSearchPageState extends State<MRTSearchPage> {
  String _selectedMRT = ' ';
  String _selectedStation = '不限';
  String _selectedRoomType = '不限';
  String _selectedRentalRange = '不限';
  String _selectedRoomCount = '不限';
  String _selectedHouseSize = '不限';
  String _selectedHouseType = '不限';
  List<String> _selectedOtherOptions = [];

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
              Text(trailingText ?? '', style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentSelection,
    required Function(String) onSelectionConfirmed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        String selectedOption = currentSelection;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                for (String option in options)
                  RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: selectedOption,
                    onChanged: (String? value) {
                      setModalState(() {
                        selectedOption = value!;
                      });
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () {
                      onSelectionConfirmed(selectedOption);
                      Navigator.pop(context);
                    },
                    child: const Text('確認'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _roomTypeBottomSheet(BuildContext context) {
    List<String> roomTypes = ['不限', '雅房', '整層住家', '獨立套房', '分租套房'];
    _showSelectionBottomSheet(
      context: context,
      title: '房屋類型',
      options: roomTypes,
      currentSelection: _selectedRoomType,
      onSelectionConfirmed: (String selectedroomtype) {
        setState(() {
          _selectedRoomType = selectedroomtype;
        });
      },
    );
  }

  void _rentalBottomSheet(BuildContext context) {
    List<String> rentalRange = [
      '不限',
      '0－5,000元',
      '5,000－10,000元',
      '10,000－15,000元',
      '15,000－20,000元',
      '20,000－30,000元',
      '30,000－40,000元',
      '40,000元以上'
    ];

    TextEditingController minController = TextEditingController();
    TextEditingController maxController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Center(
                      child: Text(
                        '租金範圍',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  ...rentalRange.map((range) {
                    return ListTile(
                      title: Text(range),
                      onTap: () {
                        Navigator.pop(context, range);
                      },
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: '最低金額',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('－'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: const InputDecoration(
                              labelText: '最高金額',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      String min = minController.text;
                      String max = maxController.text;
                      if (min.isEmpty && max.isNotEmpty) {
                        String customRange = '$max元以下';
                        Navigator.pop(context, customRange);
                      } else if (min.isNotEmpty && max.isEmpty) {
                        String customRange = '$min元以上';
                        Navigator.pop(context, customRange);
                      } else if (min.isNotEmpty && max.isNotEmpty) {
                        int minVal = int.parse(min);
                        int maxVal = int.parse(max);
                        if (minVal >= maxVal) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('輸入錯誤'),
                                content: const Text('最高金額必需大於最低金額'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('確認'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          String customRange = '$min元－$max元';
                          Navigator.pop(context, customRange);
                        }
                      }
                    },
                    child: const Text('確認'),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    ).then((selectedRange) {
      if (selectedRange != null) {
        setState(() {
          _selectedRentalRange = selectedRange;
        });
      }
    });
  }

  void _roomCountBottomSheet(BuildContext context) {
    List<String> roomcount = ['不限', '1房', '2房', '3房', '4房以上'];
    _showSelectionBottomSheet(
      context: context,
      title: '格局',
      options: roomcount,
      currentSelection: _selectedRoomCount,
      onSelectionConfirmed: (String selectedCount) {
        setState(() {
          _selectedRoomCount = selectedCount;
        });
      },
    );
  }

  void _houseSizeBottomSheet(BuildContext context) {
    List<String> housesize = [
      '不限',
      '10坪以下',
      '10－20坪',
      '20－30坪',
      '30－40坪',
      '40－50坪',
      '50坪以上'
    ];
    _showSelectionBottomSheet(
      context: context,
      title: '坪數',
      options: housesize,
      currentSelection: _selectedHouseSize,
      onSelectionConfirmed: (String selectedSize) {
        setState(() {
          _selectedHouseSize = selectedSize;
        });
      },
    );
  }

  void _houseTypeBottomSheet(BuildContext context) {
    List<String> houseTypes = ['不限', '別墅', '公寓', '電梯大樓', '透天厝'];
    _showSelectionBottomSheet(
      context: context,
      title: '房屋型態',
      options: houseTypes,
      currentSelection: _selectedHouseType,
      onSelectionConfirmed: (String selectedType) {
        setState(() {
          _selectedHouseType = selectedType;
        });
      },
    );
  }

  void _otherSelectionBottomSheet(BuildContext context) {
    List<String> options = ['不限', '有陽台', '可養寵物', '可開伙'];
    List<String> selectedOptions = ['不限'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '其他條件',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (String option in options)
                    CheckboxListTile(
                      title: Text(option),
                      value: selectedOptions.contains(option),
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (option == '不限') {
                            if (value == true) {
                              selectedOptions.clear();
                              selectedOptions.add(option);
                            } else {
                              selectedOptions.remove(option);
                            }
                          } else {
                            if (value == true) {
                              selectedOptions.remove('不限');
                              selectedOptions.add(option);
                            } else {
                              selectedOptions.remove(option);
                            }
                          }
                        });
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedOtherOptions = List.from(selectedOptions);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('確認'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            _buildListTile(
              '捷運',
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CityMRTPage()),
                );
                if (result != null &&
                    result['MRT'] != null &&
                    result['station'] != null) {
                  setState(() {
                    _selectedMRT = result['MRT'];
                    _selectedStation = result['station'];
                  });
                }
              },
              trailingText: '$_selectedMRT $_selectedStation',
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '房屋類型',
              () {
                _roomTypeBottomSheet(context);
              },
              trailingText: _selectedRoomType,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '租金',
              () {
                _rentalBottomSheet(context);
              },
              trailingText: _selectedRentalRange,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '格局',
              () {
                _roomCountBottomSheet(context);
              },
              trailingText: _selectedRoomCount,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '坪數',
              () {
                _houseSizeBottomSheet(context);
              },
              trailingText: _selectedHouseSize,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '房屋型態',
              () {
                _houseTypeBottomSheet(context);
              },
              trailingText: _selectedHouseType,
            ),
            const SizedBox(height: 10),
            _buildListTile(
              '其他',
              () {
                _otherSelectionBottomSheet(context);
              },
              trailingText: _selectedOtherOptions.isNotEmpty
                  ? _selectedOtherOptions.join(', ')
                  : '不限',
            ),
            const SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {},
                style: const ButtonStyle(
                    backgroundColor:
                        MaterialStatePropertyAll(Color(0xFF613F26))),
                child: const Text('搜尋',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}

class CityMRTPage extends StatelessWidget {
  final List<String> citiesMRT = ['台北捷運', '高雄捷運'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: const Text(
          '捷運',
          style: TextStyle(
              color: Color(0xFF613F26),
              fontWeight: FontWeight.bold,
              fontSize: 25),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: citiesMRT.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
                title: Text(citiesMRT[index],
                    style: const TextStyle(
                      color: Color.fromARGB(255, 46, 46, 46),
                      fontSize: 18,
                    )),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MRTCombinedPage(MRT: citiesMRT[index]),
                    ),
                  ).then((result) {
                    if (result != null) {
                      Navigator.pop(context, result);
                    }
                  });
                },
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10, left: 10),
                child: Divider(
                  height: 5,
                  color: Color.fromARGB(255, 221, 221, 221),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class MRTCombinedPage extends StatefulWidget {
  final String MRT;

  MRTCombinedPage({required this.MRT});

  @override
  State<MRTCombinedPage> createState() => _MRTCombinedPageState();
}

class _MRTCombinedPageState extends State<MRTCombinedPage> {
  final Map<String, Map<String, List<String>>> mrtData = {
    '台北捷運': {
      '藍線': ['善導寺站', '板橋站', '府中站'],
      '橘線': ['忠孝復興站', '東門站', '古亭站'],
      '紅線': ['大安站', '北投站', '士林站'],
    },
    '高雄捷運': {
      '黃線': ['中央公園站', '美麗島站', '高雄車站'],
      '橘線': ['鹽埕埔站', '西子灣站', '中央公圓站'],
    },
  };

  String? _selectedLine;
  List<String> _stations = [];
  String? _selectedStation;

  void _onLineChanged(String? line) {
    setState(() {
      _selectedLine = line;
      _stations = mrtData[widget.MRT]?[line ?? ''] ?? [];
      _selectedStation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = mrtData[widget.MRT]?.keys.toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: Text(
          widget.MRT,
          style: const TextStyle(
              color: Color(0xFF613F26),
              fontWeight: FontWeight.bold,
              fontSize: 25),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                if (_selectedLine != null && _selectedStation != null) {
                  Navigator.pop(context, {
                    'MRT': widget.MRT,
                    'line': _selectedLine,
                    'station': _selectedStation,
                  });
                }
              },
              child: const Text(
                '確認',
                style: TextStyle(color: Color(0xFF613F26), fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('線路',
                style: TextStyle(
                    color: Color.fromARGB(255, 46, 46, 46),
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(
              height: 10,
            ),
            DropdownButton2<String>(
              value: _selectedLine,
              hint: const Text(
                '選擇線路',
                style: TextStyle(fontSize: 17),
              ),
              items: lines.map((line) {
                return DropdownMenuItem<String>(
                  value: line,
                  child: Text(line, style: const TextStyle(fontSize: 17)),
                );
              }).toList(),
              onChanged: _onLineChanged,
              isExpanded: true,
              buttonStyleData: ButtonStyleData(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                ),
              ),
              dropdownStyleData: DropdownStyleData(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              iconStyleData: const IconStyleData(
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ),
              menuItemStyleData: const MenuItemStyleData(
                padding: EdgeInsets.symmetric(horizontal: 16),
                height: 48,
              ),
            ),
            const SizedBox(height: 20),
            if (_stations.isNotEmpty) ...[
              const Text('站點',
                  style: TextStyle(
                      color: Color.fromARGB(255, 46, 46, 46),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _stations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _stations[index],
                      style: const TextStyle(fontSize: 17),
                    ),
                    trailing: _selectedStation == _stations[index]
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedStation = _stations[index];
                      });
                    },
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}
