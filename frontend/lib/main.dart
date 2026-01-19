import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SurfingPalApp());
}

class SurfingPalApp extends StatelessWidget {
  const SurfingPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SurfingPal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
