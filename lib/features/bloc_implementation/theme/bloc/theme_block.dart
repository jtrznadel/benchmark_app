import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState.initial()) {
    on<ToggleTheme>(_onToggleTheme);
    on<EnableAccessibilityTheme>(_onEnableAccessibilityTheme);
    on<DisableAccessibilityTheme>(_onDisableAccessibilityTheme);
  }

  void _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) {
    final isDarkMode = !state.isDarkMode;
    emit(state.copyWith(
      themeData: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      isDarkMode: isDarkMode,
    ));
  }

  void _onEnableAccessibilityTheme(
      EnableAccessibilityTheme event, Emitter<ThemeState> emit) {
    emit(state.copyWith(
      themeData: AppTheme.accessibilityTheme,
      isAccessibilityMode: true,
    ));
  }

  void _onDisableAccessibilityTheme(
      DisableAccessibilityTheme event, Emitter<ThemeState> emit) {
    emit(state.copyWith(
      themeData: state.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      isAccessibilityMode: false,
    ));
  }
}