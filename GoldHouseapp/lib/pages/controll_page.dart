import 'package:flutter/material.dart';
import 'createhouse_page.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'personal_page.dart';
import 'subscription_page.dart';


class ControllPage extends StatefulWidget {
  @override
  _ControllPageState createState() => _ControllPageState();
}

class _ControllPageState extends State<ControllPage>{
  int currentTab = 0;
  final List<Widget> screens = [
    HomePage(),
    SearchPage(),
    CreateHousePage(),
    SubscriptionPage(),
    AccountPage(),
  ];
  final PageStorageBucket bucket = PageStorageBucket();
  Widget currentScreen = HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        child: currentScreen,
        bucket: bucket,
      ),
      floatingActionButton: Container(
        width: 65,
        height: 65,
        margin: EdgeInsets.only(top: 10), 
        child: FloatingActionButton(
          
          backgroundColor: Colors.white,
          onPressed: () {
            setState(() {
              currentTab = 0;  
              currentScreen = HomePage();
            });
          },
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 3,color: Color(0xFFECD8C9),),
            borderRadius: BorderRadius.all(Radius.circular(35)),  
          ),
          child: Image.asset('assets/Logo.png',fit: BoxFit.fitWidth,),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(115, 219, 219, 219),
        elevation: 0, 
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildTabItem(
              icon: Icons.search,
              index: 1,
              label: '搜尋',
            ),
            _buildTabItem(
              icon: Icons.add,
              index: 2,
              label: '刊登',
            ),
            SizedBox(width: 80),  
            _buildTabItem(
              icon: Icons.notifications,
              index: 3,
              label: '訂閱',
            ),
            _buildTabItem(
              icon: Icons.person,
              index: 4,
              label: '個人',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    return MaterialButton(
      minWidth: 40,
      onPressed: () {
        setState(() {
          currentScreen = screens[index];
          currentTab = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,  
            color: currentTab == index ? Color.fromARGB(255, 8, 0, 0) : Color.fromARGB(255, 28, 3, 3),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,  
              color: currentTab == index ? Color(0xFF613F26) : Colors.grey,
            ),
          )
        ],       
      ),
      splashColor: const Color.fromRGBO(0, 0, 0, 0),
      highlightColor: Colors.transparent,
    );
  }
}
