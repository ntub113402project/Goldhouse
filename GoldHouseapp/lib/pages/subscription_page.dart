import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'class.dart';
import 'housecard.dart';
import 'housedetail_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<Map<String, dynamic>> subscriptions = [];
  bool isLoading = true; 

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }
  
  Future<void> _fetchProperties(
      Map<String, dynamic> subscription, int index) async {
    int? subscriptionId = subscriptions[index]['subscription_id'];

    if (subscriptionId == null) {
      ('Subscription ID not found');
      return;
    }

    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/search_properties'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        ...subscription,
        'subscription_id': subscriptionId,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> properties = json.decode(response.body);
      setState(() {
        subscriptions[index]['properties'] = properties;
      });
    } else {
      ('加載失敗');
    }
  }

  Future<void> _saveSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> subscriptionList =
        subscriptions.map((sub) => json.encode(sub)).toList();
    await prefs.setStringList('subscriptions', subscriptionList);
  }

  Future<void> _loadSubscriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');

    if (memberId == null) {
      ('尚未登入');
      setState(() {
        subscriptions = [];
        isLoading = false;
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/get_subscriptions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'member_id': memberId}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        subscriptions = data
            .map((item) => {
                  'subscription_id': item['subscription_id'],
                  'city': item['city'],
                  'district': List<String>.from(item['district']),
                  'pattern': List<String>.from(item['pattern']),
                  'rentalrange': item['rentalrange'],
                  'roomcount': item['roomcount'],
                  'size': item['size'],
                  'type': List<String>.from(item['type']),
                  'properties': [],
                })
            .toList();
        isLoading = false;
      });
    } else {
      ('Failed to fetch subscriptions');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addSubscription(Map<String, dynamic> subscription) async {
    ('Adding subscription: $subscription');
    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/manage_subscription'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(subscription),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final subscriptionTime = responseData['subscription_time'];
      final subscriptionId = responseData['subscription_id'];
      setState(() {
        subscriptions.add({
          'subscription_id': subscriptionId,
          'city': subscription['city'],
          'district': subscription['district'] ?? ['不限'],
          'pattern': subscription['pattern'] ?? ['不限'],
          'rentalrange': subscription['rentalrange'] ?? '不限',
          'roomcount': subscription['roomcount'] ?? '不限',
          'size': subscription['size'] ?? '不限',
          'type': subscription['type'] ?? ['不限'],
          'properties': [],
        });
      });
      await _fetchProperties({
        ...subscription,
        'subscription_time': subscriptionTime,
      }, subscriptions.length - 1);
      await _saveSubscriptions();
    } else {
      ('新增失敗');
    }
  }

  void _removeSubscription(int index) async {
    int? subscriptionId = subscriptions[index]['subscription_id'];

    if (subscriptionId == null) {
      ('Subscription ID not found');
      return;
    }

    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/manage_subscription'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'subscription_id': subscriptionId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        subscriptions.removeAt(index);
      });
      await _saveSubscriptions();
      ('刪除成功');
    } else {
      ('刪除失敗');
    }
  }

  Future<void> _updateLastCheckTime(int subscriptionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');

    if (memberId == null) {
      ('尚未登入');
      return;
    }

    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/update_last_check_time'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'subscription_id': subscriptionId,
        'member_id': memberId,
      }),
    );

    if (response.statusCode == 200) {
      ('更新時間成功');
    } else {
      ('更新時間失敗');
    }
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
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              int? memberId = prefs.getInt('member_id');
              if (memberId == null) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    Future.delayed(const Duration(seconds: 2), () {
                      Navigator.of(context).pop();
                    });

                    return const AlertDialog(
                      backgroundColor: Color.fromARGB(255, 40, 40, 40),
                      title: Center(
                          child: Text(
                        '請先登入',
                        style: TextStyle(
                            color: Color.fromARGB(255, 243, 243, 243),
                            fontWeight: FontWeight.bold),
                      )),
                    );
                  },
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddSubscriptionPage(onSubmit: _addSubscription),
                  ),
                );
              }
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
            child: isLoading
            ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF613F26),
                    ), 
                  )          
            : subscriptions.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notification_add,
                          size: 100,
                          color: Color.fromARGB(255, 181, 181, 181),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          '尚未有訂閱條件',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color.fromARGB(255, 181, 181, 181),
                          ),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      final subscription = subscriptions[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 247, 236, 205),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 177, 177, 162)
                                  .withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(5, 5),
                            ),
                          ],
                        ),
                        margin:
                            const EdgeInsets.only(left: 10, right: 10, bottom: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Theme(
                              data: Theme.of(context).copyWith(
                                splashColor:
                                    const Color.fromARGB(0, 255, 255, 255),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${subscription['city']} ${(subscription['district'] == null || subscription['district'].isEmpty) ? '' : subscription['district'].join(', ')}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF613F26),
                                      ),
                                    ),
                                    Text(
                                      style: const TextStyle(fontSize: 16),
                                      '類型：${subscription['pattern'] == null || subscription['pattern'].isEmpty ? '不限' : subscription['pattern'].join(', ')} \n租金：${subscription['rentalrange'].isEmpty ? '' : subscription['rentalrange']}\n格局：${subscription['roomcount']}\n坪數：${subscription['size']}\n型態：${subscription['type'] == null || subscription['type'].isEmpty ? '不限' : subscription['type'].join(', ')}',
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _removeSubscription(index);
                                  },
                                ),
                                onTap: () async {
                                  int? subscriptionId =
                                      subscription['subscription_id'];
                                  if (subscriptionId != null) {
                                    await _fetchProperties(subscription, index);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PropertyDetailsPage(
                                          properties:
                                              subscription['properties'],
                                          subscription: subscription,
                                          subscriptionId: subscriptionId,
                                          onReturn: _updateLastCheckTime,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ('subscription_id is null');
                                  }
                                },
                              )),
                        ),
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
                                     
  const AddSubscriptionPage({super.key, required this.onSubmit});

  @override
  State<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  String _selectedCity = '臺北市';
  List<String> _selectedAreas = [];
  List<String> cities = ['臺北市', '新北市', '台中市'];
  Map<String, List<String>> cityDistricts = {
    '臺北市': ['中正區', '大同區', '大安區', '士林區', '萬華區'],
    '新北市': ['板橋區', '新店區', '中和區'],
    '台中市': ['北屯區', '西屯區', '南屯區'],
  };
  List<String> _selectedtype = [];
  List<String> pattern = ['整層住家', '獨立套房', '分租套房', '雅房'];
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
          padding: const EdgeInsets.all(16),
          children: [
            const Text('選擇地區',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            ...cities.map((city) => ListTile(
                  title: Text(city),
                  onTap: () => Navigator.pop(context, city),
                ))
          ].toList(),
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
            return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('選擇地區',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
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
                            .map((district) => CheckboxListTile(
                                  title: Text(district),
                                  value: selectedTemp.contains(district),
                                  onChanged: (bool? selected) {
                                    setState(() {
                                      if (selected == true) {
                                        selectedTemp.add(district);
                                      } else {
                                        selectedTemp.remove(district);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF613F26)),
                      onPressed: () => Navigator.pop(context, selectedTemp),
                      child: const Text(
                        '確認',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ));
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
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('房屋類型',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      )),
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
                      children: pattern
                          .map((pattern) => CheckboxListTile(
                                title: Text(pattern),
                                value: selectedTemp.contains(pattern) &&
                                    selectedTemp.isNotEmpty,
                                onChanged: (bool? selected) {
                                  setState(() {
                                    if (selected == true) {
                                      selectedTemp.remove('不限');
                                      selectedTemp.add(pattern);
                                    } else {
                                      selectedTemp.remove(pattern);
                                    }
                                  });
                                },
                              ))
                          .toList(),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF613F26)),
                    onPressed: () => Navigator.pop(context, selectedTemp),
                    child: const Text(
                      '確認',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
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
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF613F26)),
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
                    child: const Text(
                      '確認',
                      style: TextStyle(color: Colors.white),
                    ),
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
          padding: const EdgeInsets.all(16),
          children: [
            const Text('格局',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
            ...roomcount.map((roomcount) => ListTile(
                  title: Text(roomcount),
                  onTap: () => Navigator.pop(context, roomcount),
                ))
          ].toList(),
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
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text('坪數',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )),
          ...housesize
              .map((housesize) => ListTile(
                    title: Text(housesize),
                    onTap: () => Navigator.pop(context, housesize),
                  )),
        ]);
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
            return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('房屋型態',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
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
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF613F26)),
                      onPressed: () => Navigator.pop(context, selectedTemp),
                      child: const Text(
                        '確認',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ));
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
              title:
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Text(
                  '縣市：',
                  style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                ),
                Expanded(
                    child: Text(
                  _selectedCity,
                  style: const TextStyle(fontSize: 17),
                ))
              ]),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectCity,
            ),
            const Divider(
              height: 5,
            ),
            ListTile(
              title: Row(
                children: [
                  const Text(
                    '地區：',
                    style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                  ),
                  Expanded(
                      child: Text(
                    _selectedAreas.isEmpty ? '不限' : _selectedAreas.join(', '),
                    style: const TextStyle(fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ))
                ],
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectAreas,
            ),
            const Divider(
              height: 5,
            ),
            ListTile(
              title: Row(
                children: [
                  const Text(
                    '房屋類型：',
                    style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                  ),
                  Expanded(
                    child: Text(
                      _selectedtype.isEmpty ? '不限' : _selectedtype.join(', '),
                      style: const TextStyle(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selecttype,
            ),
            const Divider(
              height: 5,
            ),
            ListTile(
              title: Row(
                children: [
                  const Text(
                    '租金範圍：',
                    style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                  ),
                  Expanded(
                    child: Text(
                      _selectedRentalRange,
                      style: const TextStyle(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () => _rentalBottomSheet(context),
            ),
            const Divider(
              height: 5,
            ),
            ListTile(
              title: Row(
                children: [
                  const Text(
                    '格局：',
                    style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                  ),
                  Expanded(
                    child: Text(
                      _selectedRoomCount.isEmpty ? '不限' : _selectedRoomCount,
                      style: const TextStyle(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectRoomCount,
            ),
            const Divider(
              height: 5,
            ),
            ListTile(
              title: Row(
                children: [
                  const Text(
                    '坪數：',
                    style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                  ),
                  Expanded(
                    child: Text(
                      _selectedHouseSize.isEmpty ? '不限' : _selectedHouseSize,
                      style: const TextStyle(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectHouseSize,
            ),
            const Divider(
              height: 5,
            ),
            ListTile(
              title: Row(
                children: [
                  const Text(
                    '房屋型態：',
                    style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                  ),
                  Expanded(
                    child: Text(
                      _selectedTypes.isEmpty ? '不限' : _selectedTypes.join(', '),
                      style: const TextStyle(fontSize: 17),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: _selectTypes,
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF613F26)),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                int? memberid = prefs.getInt('member_id');

                if (memberid == null) {
                  ('Member ID not found');
                  return;
                }

                Map<String, dynamic> subscriptionData = {
                  'member_id': memberid,
                  'city': _selectedCity,
                  'district': _selectedAreas.isEmpty ? ['不限'] : _selectedAreas,
                  'pattern': _selectedtype.isEmpty ? ['不限'] : _selectedtype,
                  'rentalrange': _selectedRentalRange,
                  'roomcount': _selectedRoomCount,
                  'size': _selectedHouseSize,
                  'type': _selectedTypes.isEmpty ? ['不限'] : _selectedTypes,
                };

                widget.onSubmit(subscriptionData);
                Navigator.pop(context);
              },
              child: const Text(
                '新增訂閱',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PropertyDetailsPage extends StatefulWidget {
  final List<dynamic> properties;
  final Map<String, dynamic> subscription;
  final int subscriptionId;
  final Future<void> Function(int) onReturn;

  const PropertyDetailsPage({super.key, 
    required this.properties,
    required this.subscription,
    required this.subscriptionId,
    required this.onReturn,
  });

  @override
  PropertyDetailsPageState createState() => PropertyDetailsPageState();
}

class PropertyDetailsPageState extends State<PropertyDetailsPage> {
  void _handlePop(bool value) {
    widget.onReturn(widget.subscriptionId);
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
        widget.properties[index]['isFavorite'] = !isCurrentlyFavorite;
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
          widget.properties[index]['isFavorite'] = isCurrentlyFavorite;
        });
      } else {
        prefs.setStringList(
            'favoriteHids', FavoriteManager().favoriteHids.toList());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
    }
  }

  Future <void> fetchHouseDetails(BuildContext context, String hid) async {
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
    } else {
      (response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加載失敗')),
      );
    }
  }

  Future <void> clickrecord(int memberId, String hid) async {
    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000//record_click'),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFECD8C9),
          title: Text(
            '${widget.subscription['city']} - 房屋结果',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: widget.properties.isEmpty
            ? const Center(
                child: Text(
                  '尚未有新刊登的房屋',
                  style: TextStyle(
                      fontSize: 20, color: Color.fromARGB(255, 181, 181, 181)),
                ),
              )
            : ListView.builder(
                itemCount: widget.properties.length,
                itemBuilder: (context, index) {
                  final property = widget.properties[index];
                  bool isFavorite = FavoriteManager()
                      .favoriteHids
                      .contains(property['hid'].toString());
                  return HouseCard(
                    houseData: property,
                    isFavorite: isFavorite,
                    onFavoriteToggle: () =>
                        _toggleFavorite(index, property['hid']),
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      int? memberId = prefs.getInt('member_id');

                      if (memberId != null) {
                        await clickrecord(memberId, property['hid']);
                      }

                      fetchHouseDetails(context, property['hid']);
                    },
                  );
                },
              ),
      ),
    );
  }
}