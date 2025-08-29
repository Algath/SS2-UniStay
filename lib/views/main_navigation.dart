// lib/views/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:unistay/views/map_page_osm.dart';
import 'package:unistay/views/home_page.dart';
import 'package:unistay/views/profile_gate.dart';
import 'package:unistay/widgets/custom_navbar.dart';

class MainNavigation extends StatefulWidget {
  static const route = '/main';
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // Start on Home

  final List<Widget> _pages = const [
    MapPageOSM(),   // index 0
    HomePage(),     // index 1
    ProfileGate(),  // index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
