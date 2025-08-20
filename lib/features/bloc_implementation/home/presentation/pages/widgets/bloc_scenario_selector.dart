import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/benchmark/bloc/benchmark_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class BlocScenarioSelector extends StatelessWidget {
  final ScenarioType? selectedScenario;
  final int dataSize;
  final Function(ScenarioType, int) onScenarioSelected;

  const BlocScenarioSelector({
    super.key,
    required this.selectedScenario,
    required this.dataSize,
    required this.onScenarioSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildScenarioTile(
          ScenarioType.apiStreaming,
          'API Data Streaming',
          'Intensywne pobieranie i dodawanie danych co 200ms',
        ),
        _buildScenarioTile(
          ScenarioType.realtimeFiltering,
          'Real-time Data Filtering',
          'Częste filtrowanie dużego zbioru danych co 100ms',
        ),
        _buildScenarioTile(
          ScenarioType.memoryPressure,
          'Memory Pressure Simulation',
          'Cykliczne tworzenie i usuwanie rozszerzonych danych',
        ),
        _buildScenarioTile(
          ScenarioType.cascadingUpdates,
          'Cascading State Updates',
          'Wielopoziomowe aktualizacje stanu co 300ms',
        ),
        _buildScenarioTile(
          ScenarioType.highFrequency,
          'High-Frequency Updates',
          'Bardzo częste aktualizacje wielu zmiennych (60 FPS)',
        ),
        const SizedBox(height: 20),
        const Text('Wielkość zbioru danych:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSizeChip(1000),
            const SizedBox(width: 10),
            _buildSizeChip(2500),
            const SizedBox(width: 10),
            _buildSizeChip(5000),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioTile(
      ScenarioType type, String title, String description) {
    final isSelected = selectedScenario == type;
    return Card(
      color: isSelected ? Colors.blue.withOpacity(0.2) : null,
      child: ListTile(
        title: Text('${_getScenarioId(type)}: $title'),
        subtitle: Text(description),
        onTap: () => onScenarioSelected(type, dataSize),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : null,
      ),
    );
  }

  Widget _buildSizeChip(int size) {
    final isSelected = dataSize == size;
    return ChoiceChip(
      label: Text('$size'),
      selected: isSelected,
      selectedColor: Colors.blue.withOpacity(0.3),
      onSelected: (selected) {
        if (selected && selectedScenario != null) {
          onScenarioSelected(selectedScenario!, size);
        }
      },
    );
  }

  String _getScenarioId(ScenarioType type) {
    switch (type) {
      case ScenarioType.apiStreaming:
        return 'S01';
      case ScenarioType.realtimeFiltering:
        return 'S02';
      case ScenarioType.memoryPressure:
        return 'S03';
      case ScenarioType.cascadingUpdates:
        return 'S04';
      case ScenarioType.highFrequency:
        return 'S05';
    }
  }
}
