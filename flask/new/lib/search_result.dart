import 'dart:convert';
import 'dart:typed_data';  // 导入 dart:typed_data 包
import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  final List<dynamic> data;

  ResultsPage({required this.data});

  @override
  Widget build(BuildContext context) {
    // 预设图片的 base64 编码 (红色方块)
    final String defaultImageBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAI0lEQVR42mP8z/C/HwMzgPzHIsGHGhg+DAwMDAwMtQAAwXkDACgTP0uhAAAAAElFTkSuQmCC';
    final Uint8List defaultImageBytes = base64Decode(defaultImageBase64);

    return Scaffold(
      appBar: AppBar(title: Text('Search Results')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total results: ${data.length}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  // 尝试解码图片数据
                  Uint8List? imageBytes;
                  try {
                    // Debug print to check the received base64 string
                    print('Base64 image data: ${data[index]['images'][0]}');
                    imageBytes = base64Decode(data[index]['images'][0]);
                  } catch (e) {
                    print('Error decoding image: $e');
                    imageBytes = defaultImageBytes;
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // 左边的图片
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: MemoryImage(imageBytes ?? defaultImageBytes),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // 右边的描述
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data[index]['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Divider(),
                                Text('Pattern: ${data[index]['pattern']}', style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Size: ${data[index]['size']}', style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Layer: ${data[index]['layer']}', style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Type: ${data[index]['type']}', style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Price: ${data[index]['price']}', style: TextStyle(fontSize: 16, color: Colors.green)),
                                SizedBox(height: 4),
                                Text('Deposit: ${data[index]['deposit']}', style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Address: ${data[index]['address']}', style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Subway: ${data[index]['subway']}', style: TextStyle(fontSize: 16)),
                                SizedBox(height: 4),
                                Text('Bus: ${data[index]['bus']}', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}