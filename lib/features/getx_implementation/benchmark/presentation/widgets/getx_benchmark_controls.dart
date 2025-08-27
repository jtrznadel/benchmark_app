import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/features/getx_implementation/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class GetXBenchmarkControls extends StatelessWidget {
  final ScenarioType scenarioType;
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
                      'Movies: ${controller.loadedCount.value}/${controller.dataSize}'),
                  if (controller.startTime != null &&
                      controller.status.value == BenchmarkStatus.running)
                    Text(
                        'Time: ${DateTime.now().difference(controller.startTime!).inSeconds}s'),
                ],
              ),
              const SizedBox(height: 8),
              _buildScenarioSpecificInfo(),
              if (_shouldShowInteractiveControls()) ...[
                const SizedBox(height: 8),
                _buildInteractiveControls(),
              ],
            ],
          )),
    );
  }

  Widget _buildScenarioSpecificInfo() {
    return Obx(() {
      switch (scenarioType) {
        case ScenarioType.cpuProcessingPipeline:
          return Column(
            children: [
              Text(
                  'Cycle: ${controller.cpuProcessingState.value.cycleCount}/600'),
              Text(
                  'Current Step: ${controller.cpuProcessingState.value.processingStep}/5'),
              if (controller.cpuProcessingState.value.currentGenre.isNotEmpty)
                Text(
                    'Genre: ${controller.cpuProcessingState.value.currentGenre}'),
              if (controller
                  .cpuProcessingState.value.calculatedMetrics.isNotEmpty)
                Text(
                    'Avg Rating: ${controller.cpuProcessingState.value.calculatedMetrics['averageRating']?.toStringAsFixed(2) ?? 'N/A'}'),
            ],
          );
        case ScenarioType.memoryStateHistory:
          return Column(
            children: [
              Text(
                  'History Index: ${controller.currentHistoryIndex.value}/${controller.stateHistory.length}'),
              Text('Operations: ${controller.operationLog.length}'),
              if (controller.operationLog.isNotEmpty)
                Text('Last: ${controller.operationLog.last}'),
            ],
          );
        case ScenarioType.uiGranularUpdates:
          return Column(
            children: [
              Text(
                  'Frame: ${controller.frameCounter.value}/3750 (30s @ 120fps)'),
              Text('UI Elements: ${controller.uiElementStates.length}'),
              if (controller.lastUpdatedMovieIds.isNotEmpty)
                Text(
                    'Last Updated: ${controller.lastUpdatedMovieIds.length} items'),
              const Text('Level: Heavy (Max Performance Test)'),
            ],
          );
      }
    });
  }

  bool _shouldShowInteractiveControls() {
    return controller.status.value == BenchmarkStatus.running &&
        (scenarioType == ScenarioType.memoryStateHistory ||
            scenarioType == ScenarioType.uiGranularUpdates);
  }

  Widget _buildInteractiveControls() {
    if (scenarioType == ScenarioType.memoryStateHistory) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: controller.currentHistoryIndex.value > 0
                ? () {
                    controller
                        .undoToStep(controller.currentHistoryIndex.value - 1);
                  }
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Manual Undo'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              controller.applyFilterConfiguration('genre', 28);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child: const Text('Manual Filter'),
          ),
        ],
      );
    }

    // if (scenarioType == ScenarioType.uiGranularUpdates) {
    //   return Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       ElevatedButton(
    //         onPressed: () {
    //           final movieIds =
    //               controller.movies.take(10).map((m) => m.id).toList();
    //           controller.updateMovieLikeStatus(movieIds);
    //         },
    //         style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
    //         child: const Text('Manual Like Update'),
    //       ),
    //       const SizedBox(width: 8),
    //       ElevatedButton(
    //         onPressed: () {
    //           final movieIds =
    //               controller.movies.take(5).map((m) => m.id).toList();
    //           controller.updateMovieProgress(movieIds);
    //         },
    //         style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
    //         child: const Text('Manual Progress Update'),
    //       ),
    //     ],
    //   );
    // }

    return const SizedBox.shrink();
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
