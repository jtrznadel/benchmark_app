import 'package:equatable/equatable.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class HomeState extends Equatable {
  final ScenarioType? selectedScenario;
  final int dataSize;
  final TestStressLevel? selectedStressLevel; // DODANE

  const HomeState({
    this.selectedScenario,
    this.dataSize = 1000,
    this.selectedStressLevel, // DODANE
  });

  HomeState copyWith({
    ScenarioType? selectedScenario,
    int? dataSize,
    TestStressLevel? selectedStressLevel, // DODANE
  }) {
    return HomeState(
      selectedScenario: selectedScenario ?? this.selectedScenario,
      dataSize: dataSize ?? this.dataSize,
      selectedStressLevel:
          selectedStressLevel ?? this.selectedStressLevel, // DODANE
    );
  }

  @override
  List<Object?> get props =>
      [selectedScenario, dataSize, selectedStressLevel]; // ZMIENIONE
}
