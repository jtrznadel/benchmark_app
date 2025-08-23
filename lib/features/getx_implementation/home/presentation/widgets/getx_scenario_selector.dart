import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class GetXScenarioSelector extends StatelessWidget {
  final ScenarioType? selectedScenario;
  final int dataSize;
  final Function(ScenarioType, int) onScenarioSelected;

  const GetXScenarioSelector({
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
          'Intensywne przetwarzanie danych filmowych z kompleksowymi operacjami:\n• Filtrowanie według rotujących kryteriów co 100ms\n• Obliczanie złożonych agregacji i metryk matematycznych\n• Sortowanie z wielopoziomowymi porównaniami\n• Grupowanie według różnych kategorii z obliczeniami\n• 600 cykli przez 60 sekund\n\nTest pokazuje różnice w zarządzaniu stanem podczas intensywnych operacji obliczeniowych CPU.',
        ),
        _buildScenarioTile(
          ScenarioType.memoryStateHistory,
          'Memory State History',
          'Zarządzanie historią stanów z możliwością cofania operacji:\n• Intensywne cykliczne operacje filtrowania i sortowania\n• Tworzenie pełnych kopii stanu z kompleksnymi strukturami\n• Operacje undo/redo z deep copy obiektów\n• Masywne alokacje pamięci (listy, mapy, obiekty)\n• 60 sekund ciągłych operacji pamięciowych\n\nTest sprawdza efektywność zarządzania pamięcią przy immutable objects vs reactive variables.',
        ),
        _buildScenarioTile(
          ScenarioType.uiGranularUpdates,
          'UI Granular Updates',
          'Częste aktualizacje elementów interfejsu z maksymalnym obciążeniem:\n• Wysokie obciążenie UI (120 FPS, 30-40% aktualizacji)\n• Masywne aktualizacje like status, progress, ratings\n• Ciężkie operacje sortowania i filtrowania w tle\n• Intensywne obliczenia matematyczne przy każdej zmianie\n• 30 sekund nieprzerwanego testu\n\nTest mierzy precyzję przebudowywania widgetów i responsywność UI.',
        ),
        const SizedBox(height: 20),
        if (selectedScenario == ScenarioType.cpuProcessingPipeline) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: Colors.purple, size: 24),
                SizedBox(height: 8),
                Text(
                  'Scenariusz S01 - Stałe parametry',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Zbiór danych: 1000 filmów\nCykle przetwarzania: 600 (60 sekund)\nInterwał: 100ms między cyklami\nObciążenie: Maksymalne (heavy)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ] else if (selectedScenario == ScenarioType.memoryStateHistory) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.memory, color: Colors.purple, size: 24),
                SizedBox(height: 8),
                Text(
                  'Scenariusz S02 - Maksymalne obciążenie pamięci',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Zbiór danych: 1000 filmów\nInterwał operacji: 50ms\nKompleksowe obiekty: 50/cykl\nDuże listy: 30/cykl\nOperacje string: 600/cykl\nRetencja stanów: 40%',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ] else if (selectedScenario == ScenarioType.uiGranularUpdates) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: const Column(
              children: [
                Icon(Icons.speed, color: Colors.purple, size: 24),
                SizedBox(height: 8),
                Text(
                  'Scenariusz S03 - Maksymalne obciążenie UI',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'Zbiór danych: 1000 filmów\nInterwał: 8ms (120 FPS)\nAktualizacje: 30-40% obiektów/cykl\nCiężkie operacje: co 8-12 cykli\nIteracje math: 15/operację',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ] else ...[
          const Text(
            'Wielkość zbioru danych:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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

  Widget _buildScenarioTile(
      ScenarioType type, String title, String description) {
    final isSelected = selectedScenario == type;
    return Card(
      color: isSelected ? Colors.purple.withOpacity(0.2) : null,
      elevation: isSelected ? 4 : 1,
      child: ExpansionTile(
        title: Text(
          '${_getScenarioId(type)}: $title',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.purple[700] : null,
          ),
        ),
        subtitle: Text(
          _getShortDescription(type),
          style: TextStyle(
            color: isSelected ? Colors.purple[700] : Colors.grey[600],
            fontSize: 13,
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
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (type == ScenarioType.cpuProcessingPipeline ||
                          type == ScenarioType.memoryStateHistory ||
                          type == ScenarioType.uiGranularUpdates) {
                        onScenarioSelected(type, 1000);
                      } else {
                        onScenarioSelected(type, dataSize);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text('Wybierz ${_getScenarioId(type)}'),
                  ),
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
      label: Text(
        '$size',
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.purple.withOpacity(0.3),
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
        return 'Test obciążenia procesora poprzez intensywne operacje state management';
      case ScenarioType.memoryStateHistory:
        return 'Test zarządzania pamięcią przy maksymalnym obciążeniu immutable objects';
      case ScenarioType.uiGranularUpdates:
        return 'Test precyzji przebudowywania widgetów przy wysokiej częstotliwości';
    }
  }
}
