import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/models/movie.dart';
import 'package:moviedb_benchmark/core/models/processing_state.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'package:moviedb_benchmark/core/widgets/enhanced_movie_card.dart';
import 'package:moviedb_benchmark/core/models/ui_element_state.dart';
import 'package:moviedb_benchmark/core/widgets/fair_movie_card.dart';
import 'package:moviedb_benchmark/core/widgets/processing_info_display.dart';
import 'package:moviedb_benchmark/core/widgets/cpu_processing_info_display.dart';
import '../widgets/bloc_benchmark_controls.dart';
import '../../bloc/benchmark_bloc.dart';
import '../../bloc/benchmark_event.dart';
import '../../bloc/benchmark_state.dart';

class BlocBenchmarkPage extends StatefulWidget {
  final ScenarioType scenarioType;
  final int dataSize;

  const BlocBenchmarkPage({
    super.key,
    required this.scenarioType,
    required this.dataSize,
  });

  @override
  State<BlocBenchmarkPage> createState() => _BlocBenchmarkPageState();
}

class _BlocBenchmarkPageState extends State<BlocBenchmarkPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BenchmarkBloc(
        apiClient: context.read<TmdbApiClient>(),
      )..add(StartBenchmark(
          scenarioType: widget.scenarioType,
          dataSize: widget.dataSize,
        )),
      child: _BlocBenchmarkPageContent(
        scenarioType: widget.scenarioType,
        dataSize: widget.dataSize,
      ),
    );
  }
}

class _BlocBenchmarkPageContent extends StatefulWidget {
  final ScenarioType scenarioType;
  final int dataSize;

  const _BlocBenchmarkPageContent({
    required this.scenarioType,
    required this.dataSize,
  });

  @override
  State<_BlocBenchmarkPageContent> createState() =>
      _BlocBenchmarkPageContentState();
}

class _BlocBenchmarkPageContentState extends State<_BlocBenchmarkPageContent> {
  @override
  void initState() {
    super.initState();
    UIPerformanceTracker.startTracking();
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
        title: Text('BLoC: ${_getScenarioName(widget.scenarioType)}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<BenchmarkBloc, BenchmarkState>(
        builder: (context, state) {
          if (state.status == BenchmarkStatus.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text('Loading data...'),
                ],
              ),
            );
          }

          if (state.status == BenchmarkStatus.error) {
            return Center(
              child: Text(
                'Error: ${state.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return Column(
            children: [
              BlocBenchmarkControls(
                scenarioType: widget.scenarioType,
                state: state,
              ),
              Expanded(
                child: _buildScenarioContent(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScenarioContent(BuildContext context, BenchmarkState state) {
    switch (widget.scenarioType) {
      case ScenarioType.cpuProcessingPipeline:
        return _buildCpuProcessingContent(state);
      case ScenarioType.memoryStateHistory:
        return _buildMemoryScenarioContent(state);
      case ScenarioType.uiGranularUpdates:
        return _buildUiScenarioContent(context, state);
    }
  }

  Widget _buildCpuProcessingContent(BenchmarkState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CpuProcessingInfoDisplay(
            cpuProcessingState: state.cpuProcessingState,
            scenarioName: 'CPU Processing Pipeline',
          ),
          const SizedBox(height: 16),
          _buildProgressIndicator(state),
          if (state.cpuProcessingState.groupedMovies.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCpuGroupedMoviesList(state.cpuProcessingState.groupedMovies),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BenchmarkState state) {
    final progress = state.cpuProcessingState.cycleCount / 600.0;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Progress: ${(progress * 100).toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            'Cycle ${state.cpuProcessingState.cycleCount} of 600',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCpuGroupedMoviesList(Map<String, List<Movie>> groupedMovies) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ExpansionTile(
        title: Text('Processing Groups (${groupedMovies.keys.length})'),
        children: groupedMovies.entries.take(5).map((entry) {
          return ListTile(
            dense: true,
            title: Text(entry.key),
            subtitle: Text('${entry.value.length} movies'),
            trailing: Text(entry.value
                .take(2)
                .map((m) => m.title.length > 20
                    ? '${m.title.substring(0, 17)}...'
                    : m.title)
                .join(', ')),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMemoryScenarioContent(BenchmarkState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ProcessingInfoDisplay(
            processingState: state.processingState,
            cycleCount: state.currentHistoryIndex,
            scenarioName: 'Memory State History',
          ),
          _buildOperationLog(state.operationLog),
          if (state.stateHistory.isNotEmpty)
            _buildStateHistoryList(state.stateHistory),
        ],
      ),
    );
  }

  Widget _buildUiScenarioContent(BuildContext context, BenchmarkState state) {
    if (state.movies.isEmpty) {
      return const Center(child: Text('No movies loaded'));
    }

    return Column(
      children: [
        // Simple stats panel
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Frame: ${state.frameCounter}'),
              Text('Movies: ${state.movies.length}'),
              const Text('Level: HEAVY'),
            ],
          ),
        ),

        // Simple ListView with identical widgets
        Expanded(
          child: ListView.builder(
            itemCount: state.movies.length,
            itemBuilder: (context, index) {
              final movie = state.movies[index];

              return BlocBuilder<BenchmarkBloc, BenchmarkState>(
                buildWhen: (previous, current) =>
                    previous.uiElementStates[movie.id] !=
                    current.uiElementStates[movie.id],
                builder: (context, state) {
                  final uiState = state.uiElementStates[movie.id] ??
                      UIElementState(movieId: movie.id);

                  return FairMovieCard(
                    key: ValueKey(movie.id),
                    movie: movie,
                    uiState: uiState,
                    onLikeTap: () => context
                        .read<BenchmarkBloc>()
                        .add(UpdateMovieLikes([movie.id])),
                    onDownloadTap: () => context
                        .read<BenchmarkBloc>()
                        .add(UpdateMovieDownloadsBatch([movie.id])),
                  );
                },
              );
            },
          ),
        ),
      ],
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
