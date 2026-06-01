// lib/app.dart
// ─── W10: Ahora apunta a MainScreen (BottomNavigationBar) ─────
// Cambio respecto W9: home: const MainScreen()
// En W13 se envolverá en StreamBuilder para Firebase Auth
import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LockerScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      // W10: MainScreen gestiona la navegación con BottomNav
      // W13: cambiar por StreamBuilder<User?> para Firebase Auth
      home: const MainScreen(),
    );
  }
}
