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

  const SelectScenario({
    required this.scenarioType,
    required this.dataSize,
  });

  @override
  List<Object?> get props => [scenarioType, dataSize];
}
