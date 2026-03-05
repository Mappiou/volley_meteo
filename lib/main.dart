import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const VolleyMeteoApp());
}

class VolleyMeteoApp extends StatelessWidget {
  const VolleyMeteoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volley Météo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4FC3F7),
          surface: Color(0xFF1A2D40),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
