import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/features/getx_implementation/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class GetXBenchmarkControls extends StatelessWidget {
  final ScenarioType scenarioType; // ZMIANA: String -> ScenarioType
  final BenchmarkController controller;

  const GetXBenchmarkControls({
    super.key,
    required this.scenarioType,
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
                      '${_getScenarioDisplay()}: ${controller.loadedCount.value}/${controller.dataSize}'),
                ],
              ),
              const SizedBox(height: 8),
              // Progress info specific to scenario
              _buildScenarioSpecificInfo(),
              // Interactive controls for certain scenarios
              if (_shouldShowInteractiveControls()) _buildInteractiveControls(),
            ],
          )),
    );
  }

  Widget _buildScenarioSpecificInfo() {
    return Obx(() {
      switch (scenarioType) {
        case ScenarioType.apiStreaming:
          return Text(
              '${controller.statusText.value} (${controller.progressCounter.value} pages loaded)');
        case ScenarioType.realtimeFiltering:
          return Text(
              '${controller.statusText.value} - Filter cycle: ${controller.currentFilterIndex.value}');
        case ScenarioType.memoryPressure:
          return Text('${controller.statusText.value} - Memory cycles active');
        case ScenarioType.cascadingUpdates:
          return Text(
              '${controller.statusText.value} - Updates: ${controller.progressCounter.value}');
        case ScenarioType.highFrequency:
          return Column(
            children: [
              Text(controller.statusText.value),
              if (controller.multiCounters.isNotEmpty)
                Text(
                    'Counters: ${controller.multiCounters.take(5).join(", ")}...'),
            ],
          );
      }
    });
  }

  bool _shouldShowInteractiveControls() {
    return controller.status.value == BenchmarkStatus.running &&
        (scenarioType == ScenarioType.realtimeFiltering ||
            scenarioType == ScenarioType.cascadingUpdates);
  }

  Widget _buildInteractiveControls() {
    if (scenarioType == ScenarioType.realtimeFiltering) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => controller.filterMovies([28]),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Manual Filter: Action'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => controller.sortMovies(byReleaseDate: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Manual Sort: Date'),
          ),
        ],
      );
    }

    if (scenarioType == ScenarioType.cascadingUpdates) {
      return ElevatedButton(
        onPressed: controller.toggleAccessibilityMode,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
        child: Obx(() => Text(
              controller.isAccessibilityMode.value
                  ? 'Disable Accessibility'
                  : 'Enable Accessibility',
            )),
      );
    }

    return const SizedBox.shrink();
  }

  String _getScenarioDisplay() {
    switch (scenarioType) {
      case ScenarioType.apiStreaming:
        return 'Streaming';
      case ScenarioType.realtimeFiltering:
        return 'Filtering';
      case ScenarioType.memoryPressure:
        return 'Memory Load';
      case ScenarioType.cascadingUpdates:
        return 'Cascading';
      case ScenarioType.highFrequency:
        return 'High-Freq';
    }
  }

  String _getStatusText(BenchmarkStatus status) {
    switch (status) {
      case BenchmarkStatus.initial:
        return 'Initial';
      case BenchmarkStatus.loading:
        return 'Loading';
      case BenchmarkStatus.loaded:
        return 'Loaded';
      case BenchmarkStatus.running:
        return 'Running';
      case BenchmarkStatus.completed:
        return 'Completed';
      case BenchmarkStatus.error:
        return 'Error';
    }
  }
}
