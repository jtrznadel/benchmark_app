import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_stress_config.dart';
import 'package:moviedb_benchmark/core/utils/ui_stress_config.dart';

class GetXScenarioSelector extends StatelessWidget {
  final ScenarioType? selectedScenario;
  final int dataSize;
  final TestStressLevel? selectedStressLevel;
  final Function(ScenarioType, int, {TestStressLevel? stressLevel})
      onScenarioSelected; // ZMIENIONE

  const GetXScenarioSelector({
    super.key,
    required this.selectedScenario,
    required this.dataSize,
    required this.selectedStressLevel,
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
          'Częste aktualizacje elementów interfejsu:\n• Różne poziomy obciążenia UI\n• Aktualizacje like status, progress, ratings\n• Ciężkie operacje sortowania i filtrowania\n• 30 sekund testu',
        ),
        const SizedBox(height: 20),
        if (selectedScenario == ScenarioType.uiGranularUpdates) ...[
          const Text('Poziom obciążenia UI:'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStressChip(TestStressLevel.light),
              const SizedBox(width: 10),
              _buildStressChip(TestStressLevel.medium),
              const SizedBox(width: 10),
              _buildStressChip(TestStressLevel.heavy),
            ],
          ),
        ] else if (selectedScenario == ScenarioType.memoryStateHistory) ...[
          const Text('Poziom obciążenia pamięci:'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMemoryStressChip(TestStressLevel.light),
              const SizedBox(width: 10),
              _buildMemoryStressChip(TestStressLevel.medium),
              const SizedBox(width: 10),
              _buildMemoryStressChip(TestStressLevel.heavy),
            ],
          ),
        ] else ...[
          const Text('Wielkość zbioru danych:'),
          const SizedBox(height: 8),
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
      ],
    );
  }

  Widget _buildMemoryStressChip(TestStressLevel level) {
    final isSelected = selectedStressLevel == level;
    return ChoiceChip(
      label: Text(MemoryStressConfig.getLevelLabel(level)),
      selected: isSelected,
      selectedColor: Colors.purple.withOpacity(0.3),
      onSelected: (selected) {
        if (selected && selectedScenario != null) {
          onScenarioSelected(selectedScenario!, 1000, stressLevel: level);
        }
      },
    );
  }

  Widget _buildScenarioTile(
      ScenarioType type, String title, String description) {
    final isSelected = selectedScenario == type;
    return Card(
      color: isSelected ? Colors.purple.withOpacity(0.2) : null,
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
            color: isSelected ? Colors.purple[700] : Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.purple)
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
                  onPressed: () {
                    if (type == ScenarioType.uiGranularUpdates ||
                        type == ScenarioType.memoryStateHistory) {
                      onScenarioSelected(type, 1000,
                          stressLevel: selectedStressLevel);
                    } else {
                      onScenarioSelected(type, dataSize);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
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
      selectedColor: Colors.purple.withOpacity(0.3),
      onSelected: (selected) {
        if (selected && selectedScenario != null) {
          onScenarioSelected(selectedScenario!, size);
        }
      },
    );
  }

  Widget _buildStressChip(TestStressLevel level) {
    final isSelected = selectedStressLevel == level;
    return ChoiceChip(
      label: Text(UIStressConfig.getLevelLabel(level)),
      selected: isSelected,
      selectedColor: Colors.purple.withOpacity(0.3),
      onSelected: (selected) {
        if (selected && selectedScenario != null) {
          onScenarioSelected(selectedScenario!, 1000, stressLevel: level);
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
