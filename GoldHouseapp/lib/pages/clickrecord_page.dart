import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'housedetail_page.dart';

class ClickHistoryPage extends StatefulWidget {
  @override
  _ClickHistoryPageState createState() => _ClickHistoryPageState();
}

class _ClickHistoryPageState extends State<ClickHistoryPage> {
  List<dynamic> _clickHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClickHistory();
  }

  Future<void> _fetchClickHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? memberId = prefs.getInt('member_id');

    if (memberId != null) {
      final response = await http.get(
        Uri.parse('http://4.227.176.245:5000/get_clicks/$memberId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _clickHistory = json.decode(response.body);
          _isLoading = false; 
        });
      } else {
        setState(() {
          _isLoading = false; 
        });
        print('Failed to load click history: ${response.body}');
      }
    } else {
      setState(() {
        _isLoading = false; 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('請先登入')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFECD8C9),
        title: const Text(
          '瀏覽紀錄',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) 
          : _clickHistory.isEmpty
              ? Center(child: Text('尚無瀏覽紀錄'))
              : ListView.builder(
                  itemCount: _clickHistory.length,
                  itemBuilder: (context, index) {
                    var click = _clickHistory[index];
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
                          fetchHouseDetails(context, click['hid']);
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
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                    child: Image.network(
                                      click['imageUrl'],
                                      fit: BoxFit.cover,
                                      width: MediaQuery.of(context).size.width *
                                          0.35,
                                      height: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/Logo.png',
                                          fit: BoxFit.cover,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.35,
                                          height: double.infinity,
                                        );
                                      },
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
                                            '${click['pattern']} | ${click['title']}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${click['size']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.clip,
                                          ),
                                          Text(
                                            '${click['city']} ${click['district']}',
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
                                    '${click['price']}',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 249, 58, 58),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    ' 元/月',
                                    style: TextStyle(
                                        color:
                                            Color.fromARGB(255, 249, 58, 58),
                                        fontSize: 13),
                                  ),
                                ],
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
