import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final String? selectedScenario;
  final int dataSize;

  const HomeState({
    this.selectedScenario,
    this.dataSize = 500,
  });

  HomeState copyWith({
    String? selectedScenario,
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