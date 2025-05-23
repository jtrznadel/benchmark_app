import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';

class ThemeController extends GetxController {
  final isDarkMode = false.obs;
  final isAccessibilityMode = false.obs;
  
  ThemeData get theme {
    if (isAccessibilityMode.value) {
      return AppTheme.accessibilityTheme;
    }
    return isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _updateTheme();
  }

  void setAccessibilityMode(bool enabled) {
    isAccessibilityMode.value = enabled;
    _updateTheme();
  }

  void _updateTheme() {
    Get.changeTheme(theme);
  }
}