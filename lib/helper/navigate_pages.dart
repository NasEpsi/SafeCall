import 'package:flutter/material.dart';
import 'package:safecall/pages/blocked_numbers_page.dart';
import 'package:safecall/pages/home_page.dart';
import 'package:safecall/pages/recent_calls_page.dart';
import '../components/my_bottom_nav_bar.dart';

// Importez ici vos pages
// import '../pages/home_page.dart';
// import '../pages/recent_calls_page.dart';
// import '../pages/blocked_page.dart';
// import '../pages/search_page.dart';

class NavigationPages extends StatefulWidget {
  const NavigationPages({super.key});

  @override
  State<NavigationPages> createState() => _NavigationPagesState();
}

class _NavigationPagesState extends State<NavigationPages> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    RecentCallsPage(),
    const Center(child: Text('Page Recherche')),
    BlockedNumbersPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: MyBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// Navigation helper function
void navigateToPage(BuildContext context, Widget page) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => page),
  );
}