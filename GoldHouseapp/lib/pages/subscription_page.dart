import 'package:flutter/material.dart';


class SubscriptionPage extends StatefulWidget {
  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  List<Map<String, dynamic>> subscriptions = [];
  List<Map<String, String>> properties = [
    {'city': '台北市', 'area': '信義區', 'type': '獨立套房','rent': '20000', 'layout': '2房1廳'},
    {'city': '台北市', 'area': '大安區', 'type': '整層住家','rent': '25000', 'layout': '3房2廳'},
    {'city': '新北市', 'area': '板橋區', 'type': '獨立套房','rent': '15000', 'layout': '1房1廳'},
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

  List<Map<String, String>> _getMatchingProperties(Map<String, dynamic> subscription) {
    return properties
        .where((property) =>
            property['city'] == subscription['city'] &&
            (subscription['areas'].isEmpty || subscription['areas'].contains(property['area']))&&
            (subscription['type'].isEmpty || subscription['type'].contains(property['type']))
            )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFECD8C9),
        title: Image.asset("assets/logo_words.png",fit: BoxFit.contain,height: 70,),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 10,),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF613F26)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddSubscriptionPage(onSubmit: _addSubscription),
                ),
              );
            },
            child: Text('新增訂閱條件',style: TextStyle(color: const Color.fromARGB(255, 245, 245, 245)),),
          ),
          SizedBox(height: 10,),
          Expanded(
            child: ListView.builder(
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final subscription = subscriptions[index];
                final matchingProps = _getMatchingProperties(subscription);

                return ExpansionTile(
                  title: Text('${subscription['city'] }, 類型：${subscription['type'].isEmpty ? '不限' :subscription['type']}'),
                  subtitle: Text('地區：${subscription['areas'].isEmpty ? '不限' : subscription['areas'].join(', ')}'),

                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _removeSubscription(index);
                    },
                  ),
                  children: matchingProps
    .map((property) => GestureDetector(
        onTap: () { Navigator.pushNamed(context, '/housedetail'); },
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
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${property['type']} |',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                          ),
                          SizedBox(height: 2),
                          Text(
                            ' ${property['city']}${property['area']}',
                            style: TextStyle(
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
          ],
        ),
      ))
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

  AddSubscriptionPage({required this.onSubmit});

  @override
  _AddSubscriptionPageState createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends State<AddSubscriptionPage> {
  String _selectedCity = '台北市';
  List<String> _selectedAreas = [];
  List<String> availableCities = ['台北市', '新北市', '台中市'];
  List<String> _selectedtype = [];
  List<String> housetype = ['整層住家','獨立套房','分租套房','雅房'];
  Map<String, List<String>> areasByCity = {
    '台北市': ['信義區', '大安區', '中山區'],
    '新北市': ['板橋區', '新店區', '中和區'],
    '台中市': ['北屯區', '西屯區', '南屯區'],
  };

  void _selectCity() async {
    String? selectedCity = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: availableCities
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
                  title: Text('不限'),
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
                    children: areasByCity[_selectedCity]!
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
                  child: Text('確認'),
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
  void _selecttype() async{
    List<String>? selectedtype = await showModalBottomSheet<List<String>>(
      context: context,
      builder: (BuildContext context) {
        final selectedTemp = List<String>.from(_selectedtype);
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                CheckboxListTile(
                  title: Text('不限'),
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
                              value: selectedTemp.contains(type) && selectedTemp.isNotEmpty,
                              onChanged: (bool? selected) {
                                setState(() {
                                  if (selected == true) {
                                    selectedTemp.remove('不限'); // 確保不限被移除
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
                  child: Text('確認'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('新增訂閱條件'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: Text('縣市：$_selectedCity'),
              trailing: Icon(Icons.arrow_drop_down),
              onTap: _selectCity,
            ),
            ListTile(
              title: Text('地區：${_selectedAreas.isEmpty ? '不限' : _selectedAreas.join(', ')}'),
              trailing: Icon(Icons.arrow_drop_down),
              onTap: _selectAreas,
            ),
            ListTile(
              title: Text('房屋類型：${_selectedtype.isEmpty ? '不限' : _selectedtype.join(', ')}'),
              trailing: Icon(Icons.arrow_drop_down),
              onTap: _selecttype,
            ),
            ElevatedButton(
              onPressed: () {
                widget.onSubmit({
                  'city': _selectedCity,
                  'areas': _selectedAreas,
                  'type' : _selectedtype
                });
                Navigator.of(context).pop();
              },
              child: Text('確認'),
            ),
          ],
        ),
      ),
    );
  }
}
