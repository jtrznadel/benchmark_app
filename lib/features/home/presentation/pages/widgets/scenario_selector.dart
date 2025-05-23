import 'package:flutter/material.dart';

class ScenarioSelector extends StatelessWidget {
  final String? selectedScenario;
  final int dataSize;
  final Function(String, int) onScenarioSelected;

  const ScenarioSelector({
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
          'S01',
          'Preloading danych',
          'Jednorazowe pobranie zestawu danych',
        ),
        _buildScenarioTile(
          'S02',
          'Przewijanie z doładowywaniem',
          'Pobieranie kolejnych zestawów danych w trakcie przewijania',
        ),
        _buildScenarioTile(
          'S03',
          'Lokalne filtrowanie',
          'Transformacja lokalna załadowanych danych',
        ),
        _buildScenarioTile(
          'S04',
          'Przełączanie widoków',
          'Radykalna zmiana sposobu prezentacji danych',
        ),
        _buildScenarioTile(
          'S05',
          'Wielopoziomowa aktualizacja stanu',
          'Aktualizacja stanu na różnych poziomach hierarchii',
        ),
        const SizedBox(height: 20),
        const Text('Wielkość zbioru danych:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSizeChip(500),
            const SizedBox(width: 10),
            _buildSizeChip(1000),
            const SizedBox(width: 10),
            _buildSizeChip(2000),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioTile(String id, String title, String description) {
    final isSelected = selectedScenario == id;
    return Card(
      color: isSelected ? Colors.blue.withOpacity(0.2) : null,
      child: ListTile(
        title: Text('$id: $title'),
        subtitle: Text(description),
        onTap: () => onScenarioSelected(id, dataSize),
        trailing: isSelected ? const Icon(Icons.check_circle) : null,
      ),
    );
  }

  Widget _buildSizeChip(int size) {
    final isSelected = dataSize == size;
    return ChoiceChip(
      label: Text('$size'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected && selectedScenario != null) {
          onScenarioSelected(selectedScenario!, size);
        }
      },
    );
  }
}