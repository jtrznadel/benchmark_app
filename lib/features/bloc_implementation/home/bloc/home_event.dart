import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/benchmark/bloc/benchmark_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class SelectScenario extends HomeEvent {
  final ScenarioType scenarioId; // ZMIANA: String -> ScenarioType
  final int dataSize;

  const SelectScenario({
    required this.scenarioId,
    required this.dataSize,
  });

  @override
  List<Object?> get props => [scenarioId, dataSize];
}
