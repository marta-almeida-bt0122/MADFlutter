// lib/app.dart
// ─── W10: Now points to MainScreen (BottomNavigationBar) ─────
// Change from W9: home: const MainScreen()
// In W13 it will be wrapped in a StreamBuilder for Firebase Auth
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
      // W10: MainScreen manages navigation with BottomNav
      // W13: change to StreamBuilder<User?> for Firebase Auth
      home: const MainScreen(),
    );
  }
}
