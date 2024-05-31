import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubscriptionPage extends StatefulWidget {
  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<Map<String, dynamic>> subscriptions = [];
  List<Map<String, String>> properties = [
    {
      'title': '某套房',
      'city': '台北市',
      'area': '信義區',
      'type': '獨立套房',
      'price': '20000',
      'size': '10坪',
      'roomcount': '1房'
    },
    {
      'title': '某雅房',
      'city': '台北市',
      'area': '大安區',
      'type': '整層住家',
      'price': '25000',
      'size': '10坪',
      'roomcount': '1房'
    },
    {
      'title': '某分租',
      'city': '新北市',
      'area': '板橋區',
      'type': '獨立套房',
      'price': '15000',
      'size': '10坪',
      'roomcount': '1房'
    },
  ];

  void _addSubscription(Map<String, dynamic> subscription) {
    setState(() {
      subscriptions.add(subscription);
    });
  }

  void _removeSubscription(int index) {
    setState(() {
      subscriptions.removeAt(index);
    });
  }

  List<Map<String, String>> _getMatchingProperties(
      Map<String, dynamic> subscription) {
    return properties
        .where((property) =>
            property['city'] == subscription['city'] &&
            (subscription['areas'].isEmpty ||
                subscription['areas'].contains(property['area'])) &&
            (subscription['type'].isEmpty ||
                subscription['type'].contains(property['type'])))
        .toList();
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF613F26)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      AddSubscriptionPage(onSubmit: _addSubscription),
                ),
              );
            },
            child: const Text(
              '新增訂閱條件',
              style: TextStyle(color: Color.fromARGB(255, 245, 245, 245)),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: subscriptions.isEmpty
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notification_add,size: 100,color: Color.fromARGB(255, 181, 181, 181),),
                      SizedBox(height: 10,),
                      Text('尚未有訂閱條件',style: TextStyle(fontSize: 20,color: Color.fromARGB(255, 181, 181, 181),),)
                    ],
                  ),
                )
                : ListView.builder(
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final subscription = subscriptions[index];
                      final matchingProps =
                          _getMatchingProperties(subscription);

                      return ExpansionTile(
                        title: Text(
                          '${subscription['city']} ${subscription['areas'].isEmpty ? '' : subscription['areas'].join(', ')}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        subtitle: Text(
                          '類型:${subscription['type'].isEmpty ? '' : subscription['type'].join(', ')} ${subscription['rentalrange'].isEmpty ? '' : subscription['rentalrange']} 格局:${subscription['roomcount']} 坪數:${subscription['size']} ${subscription['types'].isEmpty ? '' : subscription['types'].join(', ')}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _removeSubscription(index);
                          },
                        ),
                        children: matchingProps
                            .map((property) => GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context, '/housedetail');
                                },
                                child: Container(
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
                                      Navigator.pushNamed(
                                          context, '/housedetail');
                                    },
                                    child: Stack(
                                      children: [
                                        Card(
                                          elevation: 0,
                                          margin: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              const ClipRRect(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(8),
                                                  bottomLeft:
                                                      Radius.circular(8),
                                                ),
                                                // child: Image.network(
                                                //   houses[index].imageUrl,
                                                //   fit: BoxFit.cover,
                                                //   width: MediaQuery.of(context).size.width * 0.35,
                                                //   height: double.infinity,
                                                // ),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${property['type']} | ${property['title']}',
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow.clip,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${property['size']} ${property['city']}${property['area']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.clip,
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
                                                '${property['price']}',
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
                                  ),
                                )))
                            .toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AddSubscriptionPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  AddSubscriptionPage({super.key, required this.onSubmit});

  @override
  State<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  String _selectedCity = '台北市';
  List<String> _selectedAreas = [];
  List<String> cities = ['台北市', '新北市', '台中市'];
  Map<String, List<String>> cityDistricts = {
    '台北市': ['信義區', '大安區', '中山區'],
    '新北市': ['板橋區', '新店區', '中和區'],
    '台中市': ['北屯區', '西屯區', '南屯區'],
  };
  List<String> _selectedtype = [];
  List<String> housetype = ['整層住家', '獨立套房', '分租套房', '雅房'];
  String _selectedRentalRange = '不限';
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
  List<String> roomcount = ['不限', '1房', '2房', '3房', '4房以上'];
  String _selectedRoomCount = '不限';
  List<String> housesize = [
    '不限',
    '10坪以下',
    '10－20坪',
    '20－30坪',
    '30－40坪',
    '40－50坪',
    '50坪以上'
  ];
  String _selectedHouseSize = '不限';
  List<String> houseTypes = ['別墅', '公寓', '電梯大樓', '透天厝'];
  List<String> _selectedTypes = [];

  void _selectCity() async {
    String? selectedCity = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: cities
              .map((city) => ListTile(
                    title: Text(city),
                    onTap: () => Navigator.pop(context, city),
                  ))
              .toList(),
        );
      },
    );

    if (selectedCity != null) {
      setState(() {
        _selectedCity = selectedCity;
        _selectedAreas = [];
      });
    }
  }

  void _selectAreas() async {
    List<String>? selectedAreas = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (BuildContext context) {
        final selectedTemp = List<String>.from(_selectedAreas);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                CheckboxListTile(
                  title: const Text('不限'),
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
                    children: cityDistricts[_selectedCity]!
                        .map((area) => CheckboxListTile(
                              title: Text(area),
                              value: selectedTemp.contains(area),
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected == true) {
                                    selectedTemp.add(area);
                                  } else {
                                    selectedTemp.remove(area);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedTemp),
                  child: const Text('確認'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedAreas != null) {
      setState(() {
        _selectedAreas = selectedAreas;
      });
    }
  }

  void _selecttype() async {
    List<String>? selectedtype = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (BuildContext context) {
        final selectedTemp = List<String>.from(_selectedtype);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                CheckboxListTile(
                  title: const Text('不限'),
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
                    children: housetype
                        .map((type) => CheckboxListTile(
                              title: Text(type),
                              value: selectedTemp.contains(type) &&
                                  selectedTemp.isNotEmpty,
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected == true) {
                                    selectedTemp.remove('不限');
                                    selectedTemp.add(type);
                                  } else {
                                    selectedTemp.remove(type);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedTemp),
                  child: const Text('確認'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedtype != null) {
      setState(() {
        _selectedtype = selectedtype;
      });
    }
  }

  void _rentalBottomSheet(BuildContext context) {
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
                                content: const Text('最高金額必須大於最低金額'),
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
                          String customRange = '$min－$max元';
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

  void _selectRoomCount() async {
    String? selectedRoomCount = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: roomcount
              .map((roomcount) => ListTile(
                    title: Text(roomcount),
                    onTap: () => Navigator.pop(context, roomcount),
                  ))
              .toList(),
        );
      },
    );

    if (selectedRoomCount != null) {
      setState(() {
        _selectedRoomCount = selectedRoomCount;
      });
    }
  }

  void _selectHouseSize() async {
    String? selectedHouseSize = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: housesize
              .map((housesize) => ListTile(
                    title: Text(housesize),
                    onTap: () => Navigator.pop(context, housesize),
                  ))
              .toList(),
        );
      },
    );

    if (selectedHouseSize != null) {
      setState(() {
        _selectedHouseSize = selectedHouseSize;
      });
    }
  }

  void _selectTypes() async {
    List<String>? selectedTypes = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (BuildContext context) {
        final selectedTemp = List<String>.from(_selectedTypes);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                CheckboxListTile(
                  title: const Text('不限'),
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
                    children: houseTypes
                        .map((types) => CheckboxListTile(
                              title: Text(types),
                              value: selectedTemp.contains(types) &&
                                  selectedTemp.isNotEmpty,
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected == true) {
                                    selectedTemp.remove('不限');
                                    selectedTemp.add(types);
                                  } else {
                                    selectedTemp.remove(types);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedTemp),
                  child: const Text('確認'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedTypes != null) {
      setState(() {
        _selectedTypes = selectedTypes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: const Text(
          '新增訂閱條件',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text(
                '縣市：$_selectedCity',
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectCity,
            ),
            ListTile(
              title: Text(
                  '地區：${_selectedAreas.isEmpty ? '不限' : _selectedAreas.join(', ')}'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectAreas,
            ),
            ListTile(
              title: Text(
                  '房屋類型：${_selectedtype.isEmpty ? '不限' : _selectedtype.join(', ')}'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selecttype,
            ),
            ListTile(
              title: Text('租金範圍：$_selectedRentalRange'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _rentalBottomSheet(context),
            ),
            ListTile(
              title: Text('格局：$_selectedRoomCount'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectRoomCount,
            ),
            ListTile(
              title: Text('坪數：$_selectedHouseSize'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectHouseSize,
            ),
            ListTile(
              title: Text(
                  '房屋型態：${_selectedTypes.isEmpty ? '不限' : _selectedTypes.join(', ')}'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectTypes,
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> subscriptionData = {
                  'city': _selectedCity,
                  'areas': _selectedAreas,
                  'type': _selectedtype,
                  'rentalrange': _selectedRentalRange,
                  'roomcount': _selectedRoomCount,
                  'size': _selectedHouseSize,
                  'types': _selectedTypes,
                };
                widget.onSubmit(subscriptionData);
                Navigator.pop(context);
              },
              child: const Text('確認送出'),
            ),
          ],
        ),
      ),
    );
  }
}
