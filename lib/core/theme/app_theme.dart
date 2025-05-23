import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
    );
  }

  static ThemeData get accessibilityTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18),
        bodyMedium: TextStyle(fontSize: 16),
        titleLarge: TextStyle(fontSize: 24),
      ),
    );
  }
}