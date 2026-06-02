// lib/app.dart
// ─── W13: StreamBuilder para estado de autenticación Firebase ─
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';

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
      // StreamBuilder listens to auth state changes in real time:
      // - Si hay usuario → MainScreen (con BottomNav)
      // - Si no hay usuario → LoginScreen
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Esperando conexión con Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Usuario autenticado
          if (snapshot.data != null) {
            return const MainScreen();
          }
          // No session → login screen
          return const LoginScreen();
        },
      ),
    );
  }
}
