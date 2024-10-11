import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'class.dart';
import 'housecard.dart';
import 'housedetail_page.dart';

class CollectionPage extends StatefulWidget {
  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  late Future<List<dynamic>> _favoriteHousesFuture;
  final List<String> _selectedHouses = [];
  bool ismodifyclicked = false;


  @override
  void initState() {
    super.initState();
    _favoriteHousesFuture = fetchFavorites();
  }

  Future<List<dynamic>> fetchFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');

    if (memberId != null) {
      final response = await http.get(
        Uri.parse('http://4.227.176.245:5000/favorites/$memberId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('失敗')),
        );
        return [];
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('請先登入')),
      );
      return [];
    }
  }

  void fetchHouseDetails(BuildContext context, String hid) async {
    final response =
        await http.get(Uri.parse('http://4.227.176.245:5000/houses/$hid'));

    if (response.statusCode == 200) {
      final houseDetails = json.decode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HouseDetailPage(houseDetails: houseDetails),
        ),
      );
    } else {
      print(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load house details')),
      );
    }
  }

  void deleteSelectedFavorites() async {
  if (_selectedHouses.isEmpty) {
    setState(() {
      ismodifyclicked = false;
    });
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? memberId = prefs.getInt('member_id');

  if (memberId != null) {
    List<dynamic> updatedHouses = [];

    final currentHouses = await _favoriteHousesFuture;
    updatedHouses = currentHouses.where((house) => !_selectedHouses.contains(house['hid'])).toList();

    for (var hid in _selectedHouses) {
      final response = await http.delete(
        Uri.parse('http://4.227.176.245:5000/favorites'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'member_id': memberId, 'hid': hid}),
      );

      if (response.statusCode == 200) {
        FavoriteManager().favoriteHids.remove(hid);
      } else {
      }
    }

    setState(() {
      _favoriteHousesFuture = Future.value(updatedHouses);
      _selectedHouses.clear();
      ismodifyclicked = false;
    });

    prefs.setStringList('favoriteHids', FavoriteManager().favoriteHids.toList());
  } else {

    
  }
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: const Color(0xFFECD8C9),
      title: const Text(
        '我的收藏',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        if (ismodifyclicked == false )
          TextButton(
            onPressed: () {
              setState(() {
                ismodifyclicked = !ismodifyclicked;
              });
            },
            child: Text('編輯'),
          ),
        if (ismodifyclicked == true && _selectedHouses.isEmpty)
          TextButton(
            onPressed: () {
              setState(() {
                ismodifyclicked = !ismodifyclicked;
              });
            },
            child: Text('完成'),
          ),
        if (ismodifyclicked == true && _selectedHouses.isNotEmpty)
        TextButton(
            onPressed: deleteSelectedFavorites,
            child: Text('清除'),
          ),
      ],
    ),
    body: FutureBuilder<List<dynamic>>(
      future: _favoriteHousesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF613F26),));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading favorites'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('尚未有收藏'));
        } else {
          return Column(
            children: [
              if (ismodifyclicked)
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _selectedHouses.length == snapshot.data!.length,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedHouses.clear();
                              for (var house in snapshot.data!) {
                                _selectedHouses.add(house['hid']);
                              }
                            } else {
                              _selectedHouses.clear();
                            }
                          });
                        },
                      ),
                      Text('全選'),
                    ],
                  ),
                
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var house = snapshot.data![index];
                    bool isSelected = _selectedHouses.contains(house['hid']);
                    return Stack(
                      children: [
                        HouseCard(
                          houseData: house,
                          isFavorite: false,
                          showFavoriteIcon: false,
                          onFavoriteToggle: () {},
                          onTap: () async {
                            fetchHouseDetails(context, house['hid']);
                          },
                        ),
                        if (ismodifyclicked)
                          Positioned(
                            top: 2,
                            left: 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              color: Colors.white,
                              child: Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedHouses.add(house['hid']);
                                    } else {
                                      _selectedHouses.remove(house['hid']);
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    ),
  );
}
}
