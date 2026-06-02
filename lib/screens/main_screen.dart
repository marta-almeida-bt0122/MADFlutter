// lib/screens/main_screen.dart
// ─── W10: NEW - BottomNavigationBar with 4 tabs ──────────────
// Demonstrates: StatefulWidget, setState, BottomNavigationBar,
//            organization of widgets in separate files
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'collection_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  // Index of the active tab
  int _selectedIndex = 0;

  // List of screens (same order as BottomNav items)
  // W13: LoginScreen will be added before this widget via StreamBuilder
  final List<Widget> _screens = [
    const HomeScreen(),
    const CollectionScreen(),
    const MapScreen(),
    const SettingsScreen(),
  ];

  // Called each time the user taps a tab
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene el estado de cada pantalla al
      // cambiar de tab (mejor que _screens.elementAt())
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // necesario con 4+ tabs
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Records',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
