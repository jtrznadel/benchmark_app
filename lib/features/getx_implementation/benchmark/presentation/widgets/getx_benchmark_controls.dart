import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/features/getx_implementation/benchmark/presentation/controllers/benchmark_controller.dart';

class GetXBenchmarkControls extends StatelessWidget {
  final String scenarioId;
  final BenchmarkController controller;

  const GetXBenchmarkControls({
    super.key,
    required this.scenarioId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.purple.withOpacity(0.1),
      child: Obx(() => Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Status: ${_getStatusText(controller.status.value)}'),
                  Text(
                      'Załadowano: ${controller.loadedCount.value}/${controller.dataSize}'),
                ],
              ),
              if (scenarioId == 'S03' &&
                  controller.status.value == BenchmarkStatus.running)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => controller.filterMovies([28]),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple),
                      child: const Text('Filtruj: Akcja'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          controller.sortMovies(byReleaseDate: true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple),
                      child: const Text('Sortuj: Data'),
                    ),
                  ],
                ),
              if (scenarioId == 'S05' &&
                  controller.status.value == BenchmarkStatus.running)
                ElevatedButton(
                  onPressed: controller.toggleAccessibilityMode,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: Text(
                    controller.isAccessibilityMode.value
                        ? 'Wyłącz tryb dostępności'
                        : 'Włącz tryb dostępności',
                  ),
                ),
            ],
          )),
    );
  }

  String _getStatusText(BenchmarkStatus status) {
    switch (status) {
      case BenchmarkStatus.initial:
        return 'Początkowy';
      case BenchmarkStatus.loading:
        return 'Ładowanie';
      case BenchmarkStatus.loaded:
        return 'Załadowano';
      case BenchmarkStatus.running:
        return 'W trakcie';
      case BenchmarkStatus.completed:
        return 'Zakończony';
      case BenchmarkStatus.error:
        return 'Błąd';
    }
  }
}
