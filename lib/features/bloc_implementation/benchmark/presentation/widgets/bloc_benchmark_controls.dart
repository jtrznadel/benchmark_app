import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/benchmark_bloc.dart';
import '../../bloc/benchmark_event.dart';
import '../../bloc/benchmark_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class BlocBenchmarkControls extends StatelessWidget {
  final ScenarioType scenarioType; // ZMIANA: String -> ScenarioType
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
              Text(
                  '${_getScenarioDisplay()}: ${state.loadedCount}/${state.dataSize}'),
            ],
          ),
          const SizedBox(height: 8),
          // Progress info specific to scenario
          _buildScenarioSpecificInfo(),
          // Interactive controls for certain scenarios
          if (_shouldShowInteractiveControls())
            _buildInteractiveControls(context),
        ],
      ),
    );
  }

  Widget _buildScenarioSpecificInfo() {
    switch (scenarioType) {
      case ScenarioType.apiStreaming:
        return Text(
            '${state.statusText} (${state.progressCounter} pages loaded)');
      case ScenarioType.realtimeFiltering:
        return Text(
            '${state.statusText} - Filter cycle: ${state.currentFilterIndex}');
      case ScenarioType.memoryPressure:
        return Text('${state.statusText} - Memory cycles active');
      case ScenarioType.cascadingUpdates:
        return Text('${state.statusText} - Updates: ${state.progressCounter}');
      case ScenarioType.highFrequency:
        return Column(
          children: [
            Text(state.statusText),
            if (state.multiCounters.isNotEmpty)
              Text('Counters: ${state.multiCounters.take(5).join(", ")}...'),
          ],
        );
    }
  }

  bool _shouldShowInteractiveControls() {
    // Show manual controls for certain scenarios when running
    return state.status == BenchmarkStatus.running &&
        (scenarioType == ScenarioType.realtimeFiltering ||
            scenarioType == ScenarioType.cascadingUpdates);
  }

  Widget _buildInteractiveControls(BuildContext context) {
    if (scenarioType == ScenarioType.realtimeFiltering) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              context.read<BenchmarkBloc>().add(
                    const FilterMovies(genreIds: [28]), // Action
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Manual Filter: Action'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              context.read<BenchmarkBloc>().add(
                    const SortMovies(byReleaseDate: true),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Manual Sort: Date'),
          ),
        ],
      );
    }

    if (scenarioType == ScenarioType.cascadingUpdates) {
      return ElevatedButton(
        onPressed: () {
          context.read<BenchmarkBloc>().add(ToggleAccessibilityMode());
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        child: Text(
          state.isAccessibilityMode
              ? 'Disable Accessibility'
              : 'Enable Accessibility',
        ),
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
