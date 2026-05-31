// lib/app.dart
// ─── W9: Raíz de la aplicación ────────────────────────────────
// En W10 se sustituirá home: HomeScreen() por MainScreen()
// con BottomNavigationBar
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

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
      // W10: cambiar a home: const MainScreen()
      home: const HomeScreen(),
    );
  }
}
