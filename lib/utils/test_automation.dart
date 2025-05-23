import 'dart:async';
import 'package:flutter/material.dart';

class TestAutomation {
  static Timer? _scrollTimer;

  static void startAutoScroll(
    ScrollController controller, {
    required Duration duration,
    required VoidCallback onComplete,
  }) {
    _scrollTimer?.cancel();
    
    const scrollStep = 50.0;
    const scrollInterval = Duration(milliseconds: 100);
    
    _scrollTimer = Timer.periodic(scrollInterval, (timer) {
      if (!controller.hasClients) {
        timer.cancel();
        return;
      }

      final currentPosition = controller.position.pixels;
      final maxScroll = controller.position.maxScrollExtent;

      if (currentPosition >= maxScroll) {
        timer.cancel();
        onComplete();
      } else {
        controller.jumpTo(
          (currentPosition + scrollStep).clamp(0.0, maxScroll),
        );
      }
    });
  }

  static void stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  static Future<void> measurePerformance(
    String testName,
    Future<void> Function() test,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      await test();
    } finally {
      stopwatch.stop();
      debugPrint('Test "$testName" ukończony w: ${stopwatch.elapsed}');
    }
  }
}