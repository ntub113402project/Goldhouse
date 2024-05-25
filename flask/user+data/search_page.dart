import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';
import 'main.dart';

class SearchPage extends StatefulWidget {
  
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  
  @override 
  Widget build(BuildContext context){
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
        backgroundColor: Color(0xFFECD8C9),
        title: Image.asset("assets/logo_words.png",fit: BoxFit.contain,height: 70,),
        centerTitle: true,
      ),
      body:Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20, right: 60, left: 60, bottom: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25), 
                child: Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFFECD8C9),
                    borderRadius: BorderRadius.circular(25)
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Color.fromARGB(255, 245, 245, 245),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Color(0xFF613F26),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: TextStyle(fontSize: 20),
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
          ]  
        ),
      ),
    );    
  }
}

class AreaSearchPage extends StatefulWidget {
  @override
  _AreaSearchPageState createState() => _AreaSearchPageState();
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
    try{
      //資料預處理
      String rentalRange = _selectedRentalRange == '不限' ? '' : _selectedRentalRange;
      String houseSize = _selectedHouseSize == '不限' ? '' : _selectedHouseSize;

      // 租金資料處理
      List<int>? rentalRangeList;
      if (rentalRange.contains('以下')) {
        int maxSize = int.tryParse(rentalRange.replaceAll('元以下', '').replaceAll(',', '').trim()) ?? 0;
        rentalRangeList = [-1, maxSize];
      } else if (rentalRange.contains('以上')) {
        int minSize = int.tryParse(rentalRange.replaceAll('元以上', '').replaceAll(',', '').trim()) ?? 0;
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
      Uri.parse('$flask_URL/search'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'city': _selectedCity == '不限' ? null : _selectedCity,
        'district': _selectedDistrict == '不限' ? null : _selectedDistrict,
        'room_type': _selectedRoomType == '不限' ? null : _selectedRoomType,
        'rental_range': rentalRangeList == null ? null : rentalRangeList,
        'room_count': _selectedRoomCount == '不限' ? null : int.tryParse(_selectedRoomCount.replaceAll('房', '').trim()) ?? 4,
        'house_size': houseSizeList == null ? null : houseSizeList,
        'house_type': _selectedHouseType == '不限' ? null : _selectedHouseType,
        'other_options': _selectedOtherOptions.join(',')
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('failure')),
        );
      }
    }catch(error){
      //無法連線至 flask api
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot connect to Internet or system is under maintenance')),
      );
    }
  }

  Widget _buildListTile(String titleText, void Function()? onTap, {String? trailingText}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 3,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          title: Text(titleText, style: TextStyle(color: Color(0xFF613F26), fontSize: 20)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Text(trailingText ?? '', style: TextStyle(fontSize: 15)),
              SizedBox(width: 10), 
              Icon(Icons.arrow_forward_ios, size: 18), 
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
                  padding: EdgeInsets.all(16),
                  child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  padding: EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () {
                      onSelectionConfirmed(selectedOption);
                      Navigator.pop(context);
                    },
                    child: Text('確認'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _RoomTypeBottomSheet(BuildContext context) {
    List<String> roomTypes = ['雅房','整層住家', '獨立套房', '分租套房'];
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

  void _RentalBottomSheet(BuildContext context) {
  List<String> rentalRange = [
    '不限', '0－5,000元', '5,000－10,000元', '10,000－15,000元', '15,000－20,000元',
    '20,000－30,000元', '30,000－40,000元', '40,000元以上'
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
                ListTile(
                  title: Center(
                    child: Text(
                      '租金範圍',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                }).toList(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: '最低金額',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('－'),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
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
                    }
                    else if (min.isNotEmpty && max.isEmpty) {
                      String customRange = '$min元以上';
                      Navigator.pop(context, customRange);
                    }
                    else if (min.isNotEmpty && max.isNotEmpty) {
                      int minVal = int.parse(min);
                      int maxVal = int.parse(max);
                      if (minVal >= maxVal) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('輸入錯誤'),
                              content: Text('最高金額必需大於最低金額'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('確認'),
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        String customRange = '$min－$max元';
                        Navigator.pop(context, customRange);
                      }
                    }
                  },
                  child: Text('確認'),
                ),
                SizedBox(height: 10),
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

  void _RoomCountBottomSheet(BuildContext context) {
    List<String> roomcount = ['1房', '2房', '3房', '4房以上'];
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

  void _HouseSizeBottomSheet(BuildContext context) {
    List<String> housesize = ['不限','10坪以下', '10－20坪', '20－30坪', '30－40坪','40－50坪','50坪以上'];
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
  void _HouseTypeBottomSheet(BuildContext context) {
    List<String> houseTypes = ['別墅', '公寓', '電梯大樓','透天厝'];
    _showSelectionBottomSheet(
      context: context,
      title: '房屋類型',
      options: houseTypes,
      currentSelection: _selectedHouseType,
      onSelectionConfirmed: (String selectedType) {
        setState(() {
          _selectedHouseType = selectedType;
        });
      },
    );
  }
  void _showMultipleSelectionBottomSheet(BuildContext context) {
    List<String> options = ['有陽台', '可養寵物', '可開伙'];
    List<String> selectedOptions = List.from(_selectedOtherOptions); 

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
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('其他條件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  for (String option in options)
                    CheckboxListTile(
                      title: Text(option),
                      value: selectedOptions.contains(option),
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            selectedOptions.add(option);
                          } else {
                            selectedOptions.remove(option);
                          }
                        });
                      },
                    ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedOtherOptions = List.from(selectedOptions);
                        });
                        Navigator.pop(context);
                      },
                      child: Text('確認'),
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
        padding: EdgeInsets.all(10),
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
            SizedBox(height: 10),
            _buildListTile(
              '房屋類型',
              () {
                _RoomTypeBottomSheet(context);
              },
              trailingText: _selectedRoomType,
            ),
            SizedBox(height: 10),
            _buildListTile('租金', () {
              _RentalBottomSheet(context);
            },
            trailingText: _selectedRentalRange,
            ),
            SizedBox(height: 10),
            _buildListTile('格局', () {
              _RoomCountBottomSheet(context);
            },
            trailingText: _selectedRoomCount,
            ),
            SizedBox(height: 10),
            _buildListTile('坪數', () {
              _HouseSizeBottomSheet(context);
            },
            trailingText: _selectedHouseSize,
            ),
            SizedBox(height: 10),
            _buildListTile('房屋型態', () {
              _HouseTypeBottomSheet(context);
            },
            trailingText: _selectedHouseType,
            ),
            SizedBox(height: 10),
            _buildListTile(
              '其他',
              () {
                _showMultipleSelectionBottomSheet(context);
              },
              trailingText: _selectedOtherOptions.isNotEmpty
                  ? _selectedOtherOptions.join(', ')
                  : '不限',
            ),
            SizedBox(height: 20,),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: (){
                  _search(context);
                }, 
                style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Color(0xFF613F26)),),
                child: Text('搜尋',style: TextStyle(color: const Color.fromARGB(255, 246, 246, 246),fontSize: 18),)
              ),
            )            
          ],
        ),
      ),
    );
  }
}

class CityPage extends StatelessWidget {
  final List<String> cities = ['台北市', '新北市', '基隆市', '宜蘭縣', '桃園市', '新竹市', '新竹縣', '新竹市', '高雄市',];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFECD8C9),
        title: Text('縣市',style: TextStyle(color: Color(0xFF613F26), fontWeight: FontWeight.bold,fontSize: 25),),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: cities.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
            title: Text(cities[index],style: TextStyle(color: Color.fromARGB(255, 46, 46, 46),fontSize: 18,),),
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
          Padding(
            padding: EdgeInsets.only(right: 10,left: 10),
            child: Divider(height: 5,color: const Color.fromARGB(255, 221, 221, 221),),
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

  DistrictPage({required this.city});

  @override
  _DistrictPageState createState() => _DistrictPageState();
}

class _DistrictPageState extends State<DistrictPage> {
  final Map<String, List<String>> cityDistricts = {
    '台北市': ['不限','中正區', '萬華區', '中山區','大同區','士林區'],
    '新北市': ['不限','板橋區', '中和區', '永和區'],
    '高雄市': ['不限','三民區', '鼓山區', '苓雅區'],
  };
  String? _selectedDistrict;

  @override
  Widget build(BuildContext context) {
    final districts = cityDistricts[widget.city] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFECD8C9),
        title: Text('${widget.city}',style: TextStyle(color: Color(0xFF613F26), fontWeight: FontWeight.bold,fontSize: 25),),
        centerTitle: true,
        actions: [
          Padding(padding: EdgeInsets.only(right: 10),
            child: GestureDetector(onTap: () {
              if (_selectedDistrict != null) {
                Navigator.pop(context, {'city': widget.city, 'district': _selectedDistrict});
              }
            }, child: Text('確認',style: TextStyle(color: Color(0xFF613F26),fontSize: 18),)),
          ) 
        ],
      ),
      body: ListView.builder(
        itemCount: districts.length,
        itemBuilder: (context, index) {

          return Column(
            children: [
              ListTile(
            title: Text(districts[index],style: TextStyle(color: Color.fromARGB(255, 46, 46, 46),fontSize: 18,)),
            trailing: _selectedDistrict == districts[index] ? Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _selectedDistrict = districts[index];
              });
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 10,left: 10),
            child: Divider(height: 5,color: const Color.fromARGB(255, 221, 221, 221),),
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
  _MRTSearchPageState createState() => _MRTSearchPageState();
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

  Widget _buildListTile(String titleText, void Function()? onTap, {String? trailingText}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              blurRadius: 3,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          title: Text(titleText, style: TextStyle(color: Color(0xFF613F26), fontSize: 20)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Text(trailingText ?? '', style: TextStyle(fontSize: 15)),
              SizedBox(width: 10), 
              Icon(Icons.arrow_forward_ios, size: 18), 
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
                  padding: EdgeInsets.all(16),
                  child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  padding: EdgeInsets.all(8),
                  child: ElevatedButton(
                    onPressed: () {
                      onSelectionConfirmed(selectedOption);
                      Navigator.pop(context);
                    },
                    child: Text('確認'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _RoomTypeBottomSheet(BuildContext context) {
    List<String> roomTypes = ['整層住家', '獨立套房', '分租套房'];
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

  void _RentalBottomSheet(BuildContext context) {
    List<String> rentalRange = [
      '0－5,000', '5,001－10,000', '10,001－15,000', '15,001－20,000',
      '20,001－30,000', '30,001－40,000', '40,001元以上'
    ];
    _showSelectionBottomSheet(
      context: context,
      title: '租金範圍',
      options: rentalRange,
      currentSelection: _selectedRentalRange,
      onSelectionConfirmed: (String selectedRental) {
        setState(() {
          _selectedRentalRange = selectedRental;
        });
      },
    );
  }

  void _RoomCountBottomSheet(BuildContext context) {
    List<String> roomcount = ['1房', '2房', '3房', '4房以上'];
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

  void _HouseSizeBottomSheet(BuildContext context) {
    List<String> housesize = ['10坪以下', '10－20坪', '20－30坪', '30－40坪','40－50坪','50坪以上'];
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
  void _HouseTypeBottomSheet(BuildContext context) {
    List<String> houseTypes = ['別墅', '公寓', '電梯大樓','透天厝'];
    _showSelectionBottomSheet(
      context: context,
      title: '房屋類型',
      options: houseTypes,
      currentSelection: _selectedHouseType,
      onSelectionConfirmed: (String selectedType) {
        setState(() {
          _selectedHouseType = selectedType;
        });
      },
    );
  }
  void _showMultipleSelectionBottomSheet(BuildContext context) {
    List<String> options = ['有陽台', '可養寵物', '可開伙'];
    List<String> selectedOptions = List.from(_selectedOtherOptions); 

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
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('其他條件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  for (String option in options)
                    CheckboxListTile(
                      title: Text(option),
                      value: selectedOptions.contains(option),
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            selectedOptions.add(option);
                          } else {
                            selectedOptions.remove(option);
                          }
                        });
                      },
                    ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedOtherOptions = List.from(selectedOptions);
                        });
                        Navigator.pop(context);
                      },
                      child: Text('確認'),
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
        padding: EdgeInsets.all(10),
        child: ListView(
          children: [
            _buildListTile(
  '捷運',
  () async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CityMRTPage()),
    );
    if (result != null && result['MRT'] != null && result['station'] != null) {
      setState(() {
        _selectedMRT = result['MRT'];
        _selectedStation = result['station'];
      });
    }
  },
  trailingText: '$_selectedMRT $_selectedStation',
),
            SizedBox(height: 10),
            _buildListTile(
              '房屋類型',
              () {
                _RoomTypeBottomSheet(context);
              },
              trailingText: _selectedRoomType,
            ),
            SizedBox(height: 10),
            _buildListTile('租金', () {
              _RentalBottomSheet(context);
            },
            trailingText: _selectedRentalRange,
            ),
            SizedBox(height: 10),
            _buildListTile('格局', () {
              _RoomCountBottomSheet(context);
            },
            trailingText: _selectedRoomCount,
            ),
            SizedBox(height: 10),
            _buildListTile('坪數', () {
              _HouseSizeBottomSheet(context);
            },
            trailingText: _selectedHouseSize,
            ),
            SizedBox(height: 10),
            _buildListTile('房屋型態', () {
              _HouseTypeBottomSheet(context);
            },
            trailingText: _selectedHouseType,
            ),
            SizedBox(height: 10),
            _buildListTile(
              '其他',
              () {
                _showMultipleSelectionBottomSheet(context);
              },
              trailingText: _selectedOtherOptions.isNotEmpty
                  ? _selectedOtherOptions.join(', ')
                  : '不限',
            ),
            SizedBox(height: 20,),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: (){}, 
                style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(Color(0xFF613F26)),),
                child: Text('搜尋',style: TextStyle(color: const Color.fromARGB(255, 246, 246, 246),fontSize: 18),)
              ),
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
        backgroundColor: Color(0xFFECD8C9),
        title: Text('捷運',style: TextStyle(color: Color(0xFF613F26), fontWeight: FontWeight.bold,fontSize: 25),),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: citiesMRT.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
              title: Text(citiesMRT[index],style: TextStyle(color: Color.fromARGB(255, 46, 46, 46),fontSize: 18,)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MRTCombinedPage(MRT: citiesMRT[index]),
                  ),
                ).then((result) {
                  if (result != null) {
                    Navigator.pop(context, result);
                  }
                });
            },
          ),
          Padding(
            padding: EdgeInsets.only(right: 10,left: 10),
            child: Divider(height: 5,color: const Color.fromARGB(255, 221, 221, 221),),
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
  _MRTCombinedPageState createState() => _MRTCombinedPageState();
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
        backgroundColor: Color(0xFFECD8C9),
        title: Text('${widget.MRT}',style: TextStyle(color: Color(0xFF613F26), fontWeight: FontWeight.bold,fontSize: 25),),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
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
              child: Text('確認',style: TextStyle(color: Color(0xFF613F26),fontSize: 18),),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('線路', style: TextStyle(color: Color.fromARGB(255, 46, 46, 46), fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10,),
            DropdownButton2<String>(
            value: _selectedLine,
            hint: Text(
              '選擇線路',
              style: TextStyle(fontSize: 17),
            ),
            items: lines.map((line) {
              return DropdownMenuItem<String>(
                value: line,
                child: Text(line,style: TextStyle(fontSize: 17)),
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
            iconStyleData: IconStyleData(
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
              ),
            ),
            menuItemStyleData: MenuItemStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
            ),
          ),
        
            SizedBox(height: 20),
            if (_stations.isNotEmpty) ...[
              Text('站點',style: TextStyle(color: Color.fromARGB(255, 46, 46, 46), fontSize: 22, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _stations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_stations[index],style: TextStyle(fontSize: 17),),
                    trailing: _selectedStation == _stations[index] ? Icon(Icons.check) : null,
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
