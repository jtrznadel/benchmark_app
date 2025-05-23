import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class SelectScenario extends HomeEvent {
  final String scenarioId;
  final int dataSize;

  const SelectScenario({
    required this.scenarioId,
    required this.dataSize,
  });

  @override
  List<Object?> get props => [scenarioId, dataSize];
}