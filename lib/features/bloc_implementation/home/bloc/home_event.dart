import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class SelectScenario extends HomeEvent {
  final ScenarioType scenarioType;
  final int dataSize;
  final TestStressLevel? stressLevel; // DODANE

  const SelectScenario({
    required this.scenarioType,
    required this.dataSize,
    this.stressLevel, // DODANE
  });

  @override
  List<Object?> get props => [scenarioType, dataSize, stressLevel];
}
