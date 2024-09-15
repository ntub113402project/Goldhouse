import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'class.dart';
import 'housecard.dart';
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
        _clickHistory[index]['isFavorite'] = !isCurrentlyFavorite;
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
          _clickHistory[index]['isFavorite'] = isCurrentlyFavorite;
        });
      } else {
        // 成功後更新 SharedPreferences
        prefs.setStringList(
            'favoriteHids', FavoriteManager().favoriteHids.toList());
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('請先登入')),
      );
    }
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

  void _clearclickrecord() async {
    final response = await http.post(
      Uri.parse('http://4.227.176.245:5000/clear_click_records'),
    );

    if (response.statusCode == 200) {
      setState(() {
        _clickHistory.clear();
      });
    } else {}
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
        actions: [TextButton(onPressed: _clearclickrecord, child: Text('清除'))],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _clickHistory.isEmpty
              ? Center(child: Text('尚無瀏覽紀錄'))
              : ListView.builder(
                  itemCount: _clickHistory.length,
                  itemBuilder: (context, index) {
                    var click = _clickHistory[index];
                    bool isFavorite = FavoriteManager()
                        .favoriteHids
                        .contains(click['hid'].toString());
                    return HouseCard(
                      houseData: click,
                      isFavorite: isFavorite,
                      onFavoriteToggle: () =>
                          _toggleFavorite(index, click['hid']),
                      onTap: () async {
                        fetchHouseDetails(context, click['hid']);
                      },
                    );
                  },
                ),
    );
  }
}
