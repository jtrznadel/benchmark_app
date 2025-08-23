import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class HomeState extends Equatable {
  final ScenarioType? selectedScenario;
  final int dataSize;

  const HomeState({
    this.selectedScenario,
    this.dataSize = 1000,
  });

  HomeState copyWith({
    ScenarioType? selectedScenario,
    int? dataSize,
  }) {
    return HomeState(
      selectedScenario: selectedScenario ?? this.selectedScenario,
      dataSize: dataSize ?? this.dataSize,
    );
  }

  @override
  List<Object?> get props => [selectedScenario, dataSize];
}
