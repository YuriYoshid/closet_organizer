import 'package:flutter/material.dart';
import 'declutter_screen.dart';
import 'organize_screen.dart';
import 'daily_check_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const DeclutterScreen(),
    const OrganizeScreen(),
    const DailyCheckScreen(),
  ];

  final List<String> _titles = [
    '断捨離モード',
    '整理整頓モード',
    'デイリーチェック',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: 設定画面へ
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cleaning_services),
            label: '断捨離',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.space_dashboard),
            label: '整理整頓',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'デイリー',
          ),
        ],
      ),
    );
  }
}