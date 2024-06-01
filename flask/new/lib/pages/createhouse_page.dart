import 'package:flutter/material.dart';

class CreateHousePage extends StatefulWidget {
  @override
  State<CreateHousePage> createState() => _CreateHousePageState();
}

class _CreateHousePageState extends State<CreateHousePage> {
  List<Map<String, dynamic>> createhouses = [];

  void _addhouses(Map<String, dynamic> subscription) {
    setState(() {
      createhouses.add(subscription);
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
        body: ListView(
          children: [
            const SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF613F26)),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AddPage()),
                  );
                },
                child: const Text(
                  '刊登物件',
                  style: TextStyle(color: Color.fromARGB(255, 245, 245, 245)),
                ),
              ),
            )
          ],
        ));
  }
}

class AddPage extends StatefulWidget {
  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String _selectedCity = '未選擇';
  String? _selectedArea = '未選擇';
  bool _isAreaVisible = false;
  String? _selectedhousetype = '未選擇';
  String? _selectedlessortype = '未選擇';
  List<String> _selectedchargecontain = [];
  List<String> _selectedservice = [];
  List<String> cities = ['台北市', '新北市', '台中市'];
  Map<String, List<String>> cityDistricts = {
    '台北市': ['信義區', '大安區', '中山區'],
    '新北市': ['板橋區', '新店區', '中和區'],
    '台中市': ['北屯區', '西屯區', '南屯區'],
  };
  List<String> housetype = ['整層住家', '獨立套房', '分租套房', '雅房'];
  List<String> lessortype = ['屋主', '房仲'];
  List<String> chargecontain = ['水費', '電費', '管理費', '車位費'];
  List<String> service = ['冰箱','洗衣機','電視','冷氣','熱水器','瓦斯','床','衣櫃','第四台','沙發','桌椅','陽台','電梯','車位','廚房'];
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
              trailingText != null && trailingText.length > 10 ? '${trailingText.substring(0, 10)}...' : trailingText ?? '',
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
                            children: cityDistricts[_selectedCity]!
                                .map((area) => ListTile(
                                      title: Text(area),
                                      onTap: () => Navigator.pop(context, area),
                                    ))
                                .toList(),
                          );
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
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '地址',
                  prefixIcon: Icon(Icons.map_rounded),
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
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  labelText: '刊登標題',
                  prefixIcon: Icon(Icons.mail_rounded),
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
                decoration: const InputDecoration(
                  suffixIcon: Icon(Icons.create_rounded),
                  suffixText: '元/月',
                  labelText: '租金',
                  prefixIcon: Icon(Icons.money_rounded),
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
                        return Column(
                          children: [
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
                                          value:
                                              selectedTemp.contains(contain) &&
                                                  selectedTemp.isNotEmpty,
                                          onChanged: (bool? selected) {
                                            setState(() {
                                              if (selected == true) {
                                                selectedTemp.remove('無');
                                                selectedTemp.add(contain);
                                              } else {
                                                selectedTemp.remove(contain);
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
                              child: const Text('確認'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (selectedchargecontain != null) {
                  setState(() {
                    _selectedchargecontain = selectedchargecontain;
                  });
                }
              }, trailingText: _selectedchargecontain.isNotEmpty
              ? _selectedchargecontain.join(',')
              : '無'
              ),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('房屋類型', () async {
                String? selectedhousetype = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      children: housetype
                          .map((type) => ListTile(
                                title: Text(type),
                                onTap: () => Navigator.pop(context, type),
                              ))
                          .toList(),
                    );
                  },
                );

                if (selectedhousetype != null) {
                  setState(() {
                    _selectedhousetype = selectedhousetype;
                  });
                }
              }, trailingText: _selectedhousetype),
              const SizedBox(
                height: 10,
              ),
              _buildListTile('出租人類型', () async {
                String? selectedlessortype = await showModalBottomSheet<String>(
                  context: context,
                  builder: (BuildContext context) {
                    return ListView(
                      children: lessortype
                          .map((type) => ListTile(
                                title: Text(type),
                                onTap: () => Navigator.pop(context, type),
                              ))
                          .toList(),
                    );
                  },
                );

                if (selectedlessortype != null) {
                  setState(() {
                    _selectedlessortype = selectedlessortype;
                  });
                }
              }, trailingText: _selectedlessortype),
              const SizedBox(height: 10),
              _buildListTile('傢俱', () async {
                List<String>? selectedservice=
                    await showModalBottomSheet<List<String>>(
                  context: context,
                  builder: (BuildContext context) {
                    final selectedTemp =
                        List<String>.from(_selectedservice);
                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return Column(
                          children: [
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
                                          value:
                                              selectedTemp.contains(service) &&
                                                  selectedTemp.isNotEmpty,
                                          onChanged: (bool? selected) {
                                            setState(() {
                                              if (selected == true) {
                                                selectedTemp.remove('無');
                                                selectedTemp.add(service);
                                              } else {
                                                selectedTemp.remove(service);
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
                              child: const Text('確認'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (selectedservice != null) {
                  setState(() {
                    _selectedservice = selectedservice;
                  });
                }
              }, trailingText: _selectedservice.isNotEmpty
              ? _selectedservice.join(',')
              : '無'
              ),
              const SizedBox(
                height: 10,
              ),
              const SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromARGB(255, 113, 94, 94)
                              .withOpacity(0.5),
                          blurRadius: 3,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const ListTile(
                    title: Text(
                      "型態",
                      style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromARGB(255, 113, 94, 94)
                              .withOpacity(0.5),
                          blurRadius: 3,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const ListTile(
                    title: Text(
                      "樓層",
                      style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              InkWell(
                onTap: () {},
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromARGB(255, 113, 94, 94)
                              .withOpacity(0.5),
                          blurRadius: 3,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const ListTile(
                    title: Text(
                      "其他",
                      style: TextStyle(color: Color(0xFF613F26), fontSize: 20),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
