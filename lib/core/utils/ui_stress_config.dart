import 'enums.dart';

class UIStressConfig {
  final Duration timerInterval;
  final double likeUpdatePercent;
  final double viewUpdatePercent;
  final double progressUpdatePercent;
  final double downloadUpdatePercent;
  final double ratingUpdatePercent;
  final int heavySortFrequency;
  final int heavyFilterFrequency;
  final int mathIterations;
  final String description;

  const UIStressConfig({
    required this.timerInterval,
    required this.likeUpdatePercent,
    required this.viewUpdatePercent,
    required this.progressUpdatePercent,
    required this.downloadUpdatePercent,
    required this.ratingUpdatePercent,
    required this.heavySortFrequency,
    required this.heavyFilterFrequency,
    required this.mathIterations,
    required this.description,
  });

  static UIStressConfig getConfig(TestStressLevel level) {
    switch (level) {
      case TestStressLevel.light:
        return const UIStressConfig(
          timerInterval: Duration(milliseconds: 33), // 30 FPS
          likeUpdatePercent: 0.05,
          viewUpdatePercent: 0.08,
          progressUpdatePercent: 0.03,
          downloadUpdatePercent: 0.02,
          ratingUpdatePercent: 0.01,
          heavySortFrequency: 60,
          heavyFilterFrequency: 90,
          mathIterations: 3,
          description: 'Lekkie obciążenie: 30 FPS, 5-8% aktualizacji',
        );
      case TestStressLevel.medium:
        return const UIStressConfig(
          timerInterval: Duration(milliseconds: 16), // 60 FPS
          likeUpdatePercent: 0.15,
          viewUpdatePercent: 0.20,
          progressUpdatePercent: 0.10,
          downloadUpdatePercent: 0.08,
          ratingUpdatePercent: 0.05,
          heavySortFrequency: 20,
          heavyFilterFrequency: 30,
          mathIterations: 8,
          description: 'Średnie obciążenie: 60 FPS, 15-20% aktualizacji',
        );
      case TestStressLevel.heavy:
        return const UIStressConfig(
          timerInterval: Duration(milliseconds: 8), // 120 FPS
          likeUpdatePercent: 0.30,
          viewUpdatePercent: 0.40,
          progressUpdatePercent: 0.20,
          downloadUpdatePercent: 0.15,
          ratingUpdatePercent: 0.12,
          heavySortFrequency: 8,
          heavyFilterFrequency: 12,
          mathIterations: 15,
          description: 'Wysokie obciążenie: 120 FPS, 30-40% aktualizacji',
        );
    }
  }

  static String getLevelLabel(TestStressLevel level) {
    switch (level) {
      case TestStressLevel.light:
        return 'Lekki (L1)';
      case TestStressLevel.medium:
        return 'Średni (L2)';
      case TestStressLevel.heavy:
        return 'Wysoki (L3)';
    }
  }
}
