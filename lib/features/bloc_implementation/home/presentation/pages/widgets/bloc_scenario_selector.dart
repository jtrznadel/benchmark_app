import 'package:flutter/material.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class BlocScenarioSelector extends StatefulWidget {
  final ScenarioType? selectedScenario;
  final Function(ScenarioType) onScenarioSelected;

  const BlocScenarioSelector({
    super.key,
    required this.selectedScenario,
    required this.onScenarioSelected,
  });

  @override
  State<BlocScenarioSelector> createState() => _BlocScenarioSelectorState();
}

class _BlocScenarioSelectorState extends State<BlocScenarioSelector> {
  ScenarioType? selectedScenario;

  @override
  void initState() {
    super.initState();
    selectedScenario = widget.selectedScenario;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Wybierz scenariusz testowy:',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildScenarioCard(
                ScenarioType.cpuProcessingPipeline,
                'Scenariusz S01: Obciążenie procesora',
                'Test obciążenia procesora poprzez intensywne operacje state management',
                'Scenariusz skupia się na testowaniu wydajności bibliotek zarządzania stanem podczas intensywnych operacji obliczeniowych jednostki CPU. Test realizuje szereg procesów przetwarzających dane filmowe z wykorzystaniem złożonych operacji matematycznych i logicznych.',
                Icons.memory,
                const {
                  'Zbiór danych': '1000 filmów',
                  'Cykle przetwarzania': '600 (60 sekund)',
                  'Interwał': '100ms między cyklami',
                  'Obciążenie': 'Maksymalne (heavy)',
                  'Wskaźnik': 'Wykorzystanie CPU'
                },
                const [
                  'Filtrowanie danych według zmieniających się kryteriów',
                  'Obliczanie złożonych agregacji i metryk',
                  'Sortowanie z wielopoziomowymi porównaniami',
                  'Grupowanie filmów według kategorii',
                ],
              ),
              const SizedBox(height: 16),
              _buildScenarioCard(
                ScenarioType.memoryStateHistory,
                'Scenariusz S02: Zużycie pamięci',
                'Test zarządzania pamięcią przy maksymalnym obciążeniu immutable objects',
                'Scenariusz zaprojektowany do testowania wydajności zarządzania pamięcią przez biblioteki BLoC oraz GetX. Test koncentruje się na operacjach intensywnie korzystających z pamięci RAM, symulując rzeczywiste scenariusze wymagające przechowywania historii stanów.',
                Icons.storage,
                const {
                  'Zbiór danych': '1000 filmów',
                  'Interwał operacji': '50ms',
                  'Kompleksowe obiekty': '50/cykl',
                  'Duże listy': '30/cykl',
                  'Operacje string': '600/cykl',
                  'Retencja stanów': '40%',
                  'Wskaźnik': 'Wykorzystanie pamięci'
                },
                const [
                  'Dynamiczne filtrowanie danych według różnych kryteriów',
                  'Tworzenie pełnych kopii zmian',
                  'Zarządzanie historią stanów',
                  'Tworzenie złożonych struktur danych w każdym cyklu',
                  'Kontrolowane zwalnianie pamięci',
                ],
              ),
              const SizedBox(height: 16),
              _buildScenarioCard(
                ScenarioType.uiGranularUpdates,
                'Scenariusz S03: Responsywność interfejsu użytkownika',
                'Test precyzji przebudowywania widgetów przy wysokiej częstotliwości',
                'Scenariusz testuje responsywność UI podczas częstych aktualizacji różnych elementów interfejsu. Symuluje typowe interakcje użytkownika wymagające natychmiastowej odpowiedzi interfejsu i sprawdza wydajność renderowania przy jednoczesnych zmianach wielu komponentów.',
                Icons.speed,
                const {
                  'Zbiór danych': '1000 filmów',
                  'Interwał': '8ms (120 FPS)',
                  'Aktualizacje': '30-40% obiektów/cykl',
                  'Ciężkie operacje': 'co 8-12 cykli',
                  'Iteracje math': '15/operację',
                  'Czas trwania': '30 sekund',
                  'Wskaźnik':
                      'Responsywność = 1/n * Σ(Czas reakcji - Czas akcji)'
                },
                const [
                  'Aktualizowanie statusów polubień na karcie filmu',
                  'Aktualizacja licznika wyświetleń i paska postępu',
                  'Aktualizowanie statusu pobierania',
                  'Aktualizowanie ocen filmu',
                  'Operacje sortowania, filtrowania i matematyczne w UI',
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioCard(
    ScenarioType type,
    String title,
    String shortDesc,
    String fullDesc,
    IconData icon,
    Map<String, String> params,
    List<String> operations,
  ) {
    final isSelected = selectedScenario == type;

    return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                selectedScenario = isSelected ? null : type;
              });
              if (!isSelected) {
                widget.onScenarioSelected(type);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.blue[700]
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shortDesc,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: isSelected ? Colors.blue : Colors.grey[400],
                        size: 24,
                      ),
                    ],
                  ),

                  // Expanded content
                  if (isSelected) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Szczegółowy opis',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Operations
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.settings,
                                  color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Główne operacje testowe',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...operations.map((operation) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(
                                          top: 6, right: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        operation,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Parameters
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.analytics,
                                  color: Colors.blue[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Parametry techniczne',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...params.entries.map((entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        '${entry.key}:',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildScenarioTile(
      ScenarioType type, String title, String description) {
    final isSelected = selectedScenario == type;
    return Card(
      color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      elevation: isSelected ? 4 : 1,
      child: ExpansionTile(
        title: Text(
          '${_getScenarioId(type)}: $title',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue[700] : null,
          ),
        ),
        subtitle: Text(
          _getShortDescription(type),
          style: TextStyle(
            color: isSelected ? Colors.blue[700] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue[600])
            : null,
        onExpansionChanged: (expanded) {
          if (expanded) {
            setState(() {
              selectedScenario = type;
            });
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    ScenarioType? chipScenario, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final isSelected = selectedScenario == chipScenario;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.blue[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.blue.withOpacity(0.3),
      onSelected: (selected) {
        if (selected && selectedScenario != null) {
          onPressed();
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
