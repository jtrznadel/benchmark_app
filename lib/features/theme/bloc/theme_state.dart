import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/core/theme/app_theme.dart';

class ThemeState extends Equatable {
  final ThemeData themeData;
  final bool isDarkMode;
  final bool isAccessibilityMode;

  const ThemeState({
    required this.themeData,
    this.isDarkMode = false,
    this.isAccessibilityMode = false,
  });

  factory ThemeState.initial() {
    return ThemeState(
      themeData: AppTheme.lightTheme,
      isDarkMode: false,
      isAccessibilityMode: false,
    );
  }

  ThemeState copyWith({
    ThemeData? themeData,
    bool? isDarkMode,
    bool? isAccessibilityMode,
  }) {
    return ThemeState(
      themeData: themeData ?? this.themeData,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isAccessibilityMode: isAccessibilityMode ?? this.isAccessibilityMode,
    );
  }

  @override
  List<Object> get props => [themeData, isDarkMode, isAccessibilityMode];
}
