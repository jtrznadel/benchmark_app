import 'package:equatable/equatable.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class ToggleTheme extends ThemeEvent {}

class EnableAccessibilityTheme extends ThemeEvent {}

class DisableAccessibilityTheme extends ThemeEvent {}