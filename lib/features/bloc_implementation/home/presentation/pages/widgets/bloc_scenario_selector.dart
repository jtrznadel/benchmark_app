import 'package:flutter/material.dart';
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
          ScenarioType.cpuProcessingPipeline,
          'CPU Processing Pipeline',
          'Intensywne przetwarzanie danych filmowych:\n• Filtrowanie według gatunku co 100ms\n• Obliczanie średnich ocen\n• Sortowanie według metryki\n• Grupowanie według dekad\n• 600 cykli przez 60 sekund',
        ),
        _buildScenarioTile(
          ScenarioType.memoryStateHistory,
          'Memory State History',
          'Zarządzanie historią stanów z możliwością cofania:\n• Cykliczne operacje filtrowania\n• Tworzenie pełnych kopii stanu\n• Operacje undo/redo\n• 400 operacji przez 60 sekund',
        ),
        _buildScenarioTile(
          ScenarioType.uiGranularUpdates,
          'UI Granular Updates',
          'Częste aktualizacje elementów interfejsu:\n• 60 FPS aktualizacje\n• 10% filmów - like status\n• 20% filmów - licznik wyświetleń\n• 5% filmów - postęp oglądania\n• 1800 klatek przez 30 sekund',
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
      child: ExpansionTile(
        title: Text(
          '${_getScenarioId(type)}: $title',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          _getShortDescription(type),
          style: TextStyle(
            color: isSelected ? Colors.blue[700] : Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : const Icon(Icons.info_outline),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => onScenarioSelected(type, dataSize),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Wybierz ${_getScenarioId(type)}'),
                ),
              ],
            ),
          ),
        ],
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
      case ScenarioType.cpuProcessingPipeline:
        return 'S01';
      case ScenarioType.memoryStateHistory:
        return 'S02';
      case ScenarioType.uiGranularUpdates:
        return 'S03';
    }
  }

  String _getShortDescription(ScenarioType type) {
    switch (type) {
      case ScenarioType.cpuProcessingPipeline:
        return 'Test obciążenia procesora poprzez state management';
      case ScenarioType.memoryStateHistory:
        return 'Test zarządzania pamięcią przy immutable objects';
      case ScenarioType.uiGranularUpdates:
        return 'Test precyzji przebudowywania widgetów';
    }
  }
}
