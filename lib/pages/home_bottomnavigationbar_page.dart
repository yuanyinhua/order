import 'package:flutter/material.dart';

import 'home_page.dart';
import 'package:m/api/constant.dart';

class HomeBottomNavigationBarPage extends StatefulWidget {
  const HomeBottomNavigationBarPage({Key? key}) : super(key: key);
  @override
  _HomeBottomNavigationBarPageState createState() => _HomeBottomNavigationBarPageState();
}

class _HomeBottomNavigationBarPageState extends State<HomeBottomNavigationBarPage> {
  int _currentIndex = 0;
  final _pageController = PageController();

  late List _bottomNavPages; // 底部导航栏各个可切换页面组

  @override
  void initState() {
    HomePage page1 = const HomePage(key: Key(kBaseQiziUrl), baseUrl: kBaseQiziUrl);
    HomePage page2 = const HomePage(key: Key(kBaseQifengUrl), baseUrl: kBaseQifengUrl);
    _bottomNavPages = [page1, page2];    
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

    void _pageChanged(int index) {
    setState(() {
      if (_currentIndex != index) _currentIndex = index;;
    });
  }

  void _onTap(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: _pageChanged,
          itemCount: _bottomNavPages.length,
          itemBuilder: (context, index) {
            return _bottomNavPages[index];
          }),
      backgroundColor: Colors.transparent,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '启子'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: '启风'),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.teal,
        onTap: _onTap,
      ),
    );
  }
}

