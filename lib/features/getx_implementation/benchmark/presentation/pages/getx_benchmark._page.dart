import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/models/processing_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'package:moviedb_benchmark/core/widgets/enhanced_movie_card.dart';
import 'package:moviedb_benchmark/core/models/ui_element_state.dart';
import 'package:moviedb_benchmark/core/widgets/processing_info_display.dart';
import '../controllers/benchmark_controller.dart';
import '../widgets/getx_benchmark_controls.dart';

class GetXBenchmarkPage extends StatefulWidget {
  final ScenarioType scenarioType;
  final int dataSize;
  final TestStressLevel? stressLevel; // DODANE

  const GetXBenchmarkPage({
    super.key,
    required this.scenarioType,
    required this.dataSize,
    this.stressLevel, // DODANE
  });

  @override
  State<GetXBenchmarkPage> createState() => _GetXBenchmarkPageState();
}

class _GetXBenchmarkPageState extends State<GetXBenchmarkPage> {
  final controller = Get.put(BenchmarkController());

  @override
  void initState() {
    super.initState();
    UIPerformanceTracker.startTracking();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ZMIENIONE - przekaż stressLevel
      controller.startBenchmark(widget.scenarioType, widget.dataSize,
          stress: widget.stressLevel);
    });
  }

  @override
  void dispose() {
    UIPerformanceTracker.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GetX: ${_getScenarioName(widget.scenarioType)}'),
        backgroundColor: Colors.purple,
      ),
      body: Obx(() {
        if (controller.status.value == BenchmarkStatus.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purple),
                SizedBox(height: 16),
                Text('Loading data...'),
              ],
            ),
          );
        }

        if (controller.status.value == BenchmarkStatus.error) {
          return Center(
            child: Text(
              'Error: ${controller.error.value}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return Column(
          children: [
            GetXBenchmarkControls(
              scenarioType: widget.scenarioType,
              controller: controller,
            ),
            Expanded(
              child: _buildScenarioContent(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildScenarioContent() {
    return Obx(() {
      switch (widget.scenarioType) {
        case ScenarioType.cpuProcessingPipeline:
          return _buildCpuScenarioContent();
        case ScenarioType.memoryStateHistory:
          return _buildMemoryScenarioContent();
        case ScenarioType.uiGranularUpdates:
          return _buildUiScenarioContent();
      }
    });
  }

  Widget _buildCpuScenarioContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProcessingInfoDisplay(
            processingState: controller.processingState.value,
            cycleCount: controller.currentProcessingCycle.value,
            scenarioName: 'CPU Processing Pipeline',
          ),
          if (controller.processingState.value.groupedMovies.isNotEmpty)
            _buildGroupedMoviesList(
                controller.processingState.value.groupedMovies),
        ],
      ),
    );
  }

  Widget _buildMemoryScenarioContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProcessingInfoDisplay(
            processingState: controller.processingState.value,
            cycleCount: controller.currentHistoryIndex.value,
            scenarioName: 'Memory State History',
          ),
          _buildOperationLog(controller.operationLog),
          if (controller.stateHistory.isNotEmpty)
            _buildStateHistoryList(controller.stateHistory),
        ],
      ),
    );
  }

  Widget _buildUiScenarioContent() {
    if (controller.movies.isEmpty) {
      return const Center(child: Text('No movies loaded'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.purple.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Frame: ${controller.frameCounter.value}'),
              Text('Movies: ${controller.movies.length}'),
              Text('Updates: ${controller.lastUpdatedMovieIds.length}'),
              // DODANE - pokaż poziom stresu
              if (widget.stressLevel != null)
                Text('Level: ${widget.stressLevel.toString().split('.').last}'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: controller.movies.length,
            itemBuilder: (context, index) {
              final movie = controller.movies[index];
              return Obx(() {
                final uiState = controller.uiElementStates[movie.id] ??
                    UIElementState(movieId: movie.id);

                return EnhancedMovieCard(
                  movie: movie,
                  uiState: uiState,
                  onLikeTap: () {
                    controller.updateMovieLikeStatus([movie.id]);
                  },
                  onDownloadTap: () {
                    controller.updateMovieDownloadStatus([movie.id]);
                  },
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedMoviesList(Map<String, List<Movie>> groupedMovies) {
    return ExpansionTile(
      title: Text('Grouped Movies (${groupedMovies.keys.length} groups)'),
      children: groupedMovies.entries.map((entry) {
        return ListTile(
          title: Text(entry.key),
          subtitle: Text('${entry.value.length} movies'),
          trailing: Text(entry.value.take(3).map((m) => m.title).join(', ')),
        );
      }).toList(),
    );
  }

  Widget _buildOperationLog(List<String> operationLog) {
    return ExpansionTile(
      title: Text('Operation Log (${operationLog.length} operations)'),
      children: operationLog.reversed.take(10).map((operation) {
        return ListTile(
          dense: true,
          title: Text(operation),
        );
      }).toList(),
    );
  }

  Widget _buildStateHistoryList(List<ProcessingState> stateHistory) {
    return ExpansionTile(
      title: Text('State History (${stateHistory.length} states)'),
      children: stateHistory.reversed.take(5).map((state) {
        return ListTile(
          dense: true,
          title: Text('Step ${state.processingStep}'),
          subtitle: Text('${state.filteredMovies.length} filtered movies'),
          trailing:
              Text(state.timestamp.toString().split(' ')[1].substring(0, 8)),
        );
      }).toList(),
    );
  }

  String _getScenarioName(ScenarioType type) {
    switch (type) {
      case ScenarioType.cpuProcessingPipeline:
        return 'S01 - CPU Processing';
      case ScenarioType.memoryStateHistory:
        return 'S02 - Memory History';
      case ScenarioType.uiGranularUpdates:
        return 'S03 - UI Updates';
    }
  }
}
