// filepath: /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0/lib/main.dart
import 'login_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reckon Seller',
      theme: ThemeData(
        useMaterial3: true,
        // Using a sophisticated Teal/Blue seed
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C70),
          brightness: Brightness.light,
        ),
        // Customizing the input decoration theme globally for consistency
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.withAlpha(13), // Very subtle fill
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none, // No border by default (cleaner look)
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF006C70), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

