// lib/screens/main_screen.dart
// ─── W10: NUEVO - BottomNavigationBar con 4 tabs ──────────────
// Demuestra: StatefulWidget, setState, BottomNavigationBar,
//            organización de widgets en ficheros separados
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

  // Índice de la pestaña activa
  int _selectedIndex = 0;

  // Lista de pantallas (mismo orden que los items del BottomNav)
  // W13: LoginScreen se añade antes de este widget via StreamBuilder
  final List<Widget> _screens = [
    const HomeScreen(),
    const CollectionScreen(),
    const MapScreen(),
    const SettingsScreen(),
  ];

  // Se llama cada vez que el usuario toca un tab
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
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Registros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
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
