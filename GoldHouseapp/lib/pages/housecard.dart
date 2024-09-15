import 'package:flutter/material.dart';

class HouseCard extends StatelessWidget {
  final Map<String, dynamic> houseData;
  final bool isFavorite;
  final bool showFavoriteIcon;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const HouseCard({
    Key? key,
    required this.houseData,
    required this.isFavorite,
    this.showFavoriteIcon = true, // 默認顯示愛心圖標
    required this.onFavoriteToggle,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
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
                  Stack(
                    children: [
                      SizedBox(
                        width: 150,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          child: Image.network(
                            houseData['imageUrl'],
                            fit: BoxFit.fill,
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Image(
                                  image: AssetImage('assets/Logo.png'));
                            },
                          ),
                        ),
                      ),
                      if (showFavoriteIcon) 
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border),
                            color: Color.fromARGB(255, 168, 26, 16),
                            onPressed: onFavoriteToggle,
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${houseData['pattern']} | ${houseData['title']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${houseData['size']}',
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${houseData['city']} ${houseData['district']}',
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
                '${houseData['price']}元/月',
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
  }
}
