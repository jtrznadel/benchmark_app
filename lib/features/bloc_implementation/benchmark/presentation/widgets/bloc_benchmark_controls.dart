import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/benchmark_bloc.dart';
import '../../bloc/benchmark_event.dart';
import '../../bloc/benchmark_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class BlocBenchmarkControls extends StatelessWidget {
  final ScenarioType scenarioType;
  final BenchmarkState state;

  const BlocBenchmarkControls({
    super.key,
    required this.scenarioType,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blue.withOpacity(0.1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Status: ${_getStatusText(state.status)}'),
              Text('Movies: ${state.loadedCount}/${state.dataSize}'),
              if (state.startTime != null &&
                  state.status == BenchmarkStatus.running)
                Text(
                    'Time: ${DateTime.now().difference(state.startTime!).inSeconds}s'),
            ],
          ),
          const SizedBox(height: 8),
          _buildScenarioSpecificInfo(),
          if (_shouldShowInteractiveControls()) ...[
            const SizedBox(height: 8),
            _buildInteractiveControls(context),
          ],
        ],
      ),
    );
  }

  Widget _buildScenarioSpecificInfo() {
    switch (scenarioType) {
      case ScenarioType.cpuProcessingPipeline:
        return Column(
          children: [
            Text('Processing Cycle: ${state.currentProcessingCycle}'),
            Text('Current Step: ${state.processingState.processingStep}/5'),
            if (state.processingState.currentGenre.isNotEmpty)
              Text('Genre: ${state.processingState.currentGenre}'),
            if (state.processingState.calculatedMetrics.isNotEmpty)
              Text(
                  'Avg Rating: ${state.processingState.calculatedMetrics['averageRating']?.toStringAsFixed(2) ?? 'N/A'}'),
          ],
        );
      case ScenarioType.memoryStateHistory:
        return Column(
          children: [
            Text(
                'History Index: ${state.currentHistoryIndex}/${state.stateHistory.length}'),
            Text('Operations: ${state.operationLog.length}'),
            if (state.operationLog.isNotEmpty)
              Text('Last: ${state.operationLog.last}'),
          ],
        );
      case ScenarioType.uiGranularUpdates:
        return Column(
          children: [
            Text('Frame: ${state.frameCounter}/1800'),
            Text('UI Elements: ${state.uiElementStates.length}'),
            if (state.lastUpdatedMovieIds.isNotEmpty)
              Text('Last Updated: ${state.lastUpdatedMovieIds.length} items'),
          ],
        );
    }
  }

  bool _shouldShowInteractiveControls() {
    return state.status == BenchmarkStatus.running &&
        (scenarioType == ScenarioType.memoryStateHistory ||
            scenarioType == ScenarioType.uiGranularUpdates);
  }

  Widget _buildInteractiveControls(BuildContext context) {
    if (scenarioType == ScenarioType.memoryStateHistory) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: state.currentHistoryIndex > 0
                ? () {
                    context.read<BenchmarkBloc>().add(UndoLastOperation());
                  }
                : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Manual Undo'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context
                  .read<BenchmarkBloc>()
                  .add(const ApplyFilterConfiguration('genre', 28));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Manual Filter'),
          ),
        ],
      );
    }

    if (scenarioType == ScenarioType.uiGranularUpdates) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              final movieIds = state.movies.take(10).map((m) => m.id).toList();
              context
                  .read<BenchmarkBloc>()
                  .add(UpdateMovieLikeStatus(movieIds));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Manual Like Update'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final movieIds = state.movies.take(5).map((m) => m.id).toList();
              context.read<BenchmarkBloc>().add(UpdateMovieProgress(movieIds));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Manual Progress Update'),
          ),
        ],
      );
    }

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
