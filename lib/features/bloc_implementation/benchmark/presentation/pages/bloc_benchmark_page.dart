import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/memory_monitor.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/theme/bloc/theme_block.dart';
import '../../../../../core/widgets/movie_list_item.dart';
import '../../../../../core/widgets/movie_grid_item.dart';
import '../widgets/bloc_benchmark_controls.dart';
import '../../../theme/bloc/theme_event.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BenchmarkBloc(
            apiClient: context.read<TmdbApiClient>(),
          )..add(StartBenchmark(
              scenarioType: widget.scenarioType, dataSize: widget.dataSize)),
        ),
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
      ],
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
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    UIPerformanceTracker.startTracking(); // ZMIANA
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    UIPerformanceTracker.stopTracking(); // ZMIANA
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BenchmarkBloc, BenchmarkState>(
      listener: (context, state) {
        if (state.isAccessibilityMode) {
          context.read<ThemeBloc>().add(EnableAccessibilityTheme());
        } else {
          context.read<ThemeBloc>().add(DisableAccessibilityTheme());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text('BLoC Benchmark: ${_getScenarioName(widget.scenarioType)}'),
          backgroundColor: Colors.blue,
          actions: [
            BlocBuilder<BenchmarkBloc, BenchmarkState>(
              builder: (context, state) {
                if (state.status == BenchmarkStatus.running ||
                    state.status == BenchmarkStatus.loaded) {
                  return IconButton(
                    icon: Icon(
                      state.viewMode == ViewMode.list
                          ? Icons.grid_view
                          : Icons.list,
                    ),
                    onPressed: () {
                      context.read<BenchmarkBloc>().add(ToggleViewMode());
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
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
                  child: _buildMovieView(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMovieView(BuildContext context, BenchmarkState state) {
    // For scenarios that use enriched movies, show those
    if (state.enrichedMovies.isNotEmpty) {
      return _buildEnrichedMovieView(state);
    }

    // For high frequency scenario, show counters
    if (widget.scenarioType == ScenarioType.highFrequency) {
      return _buildHighFrequencyView(state);
    }

    // Default movie view
    if (state.filteredMovies.isEmpty) {
      return const Center(child: Text('No movies to display'));
    }

    if (state.viewMode == ViewMode.grid) {
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: state.filteredMovies.length,
        itemBuilder: (context, index) {
          final movie = state.filteredMovies[index];
          return MovieGridItem(
            movie: movie,
            isExpanded: state.expandedMovies.contains(movie.id),
            isAccessibilityMode: state.isAccessibilityMode,
            onTap: () {
              context.read<BenchmarkBloc>().add(
                    ToggleMovieExpanded(movieId: movie.id),
                  );
            },
          );
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: state.filteredMovies.length,
        itemBuilder: (context, index) {
          final movie = state.filteredMovies[index];
          return MovieListItem(
            movie: movie,
            isExpanded: state.expandedMovies.contains(movie.id),
            isAccessibilityMode: state.isAccessibilityMode,
            onTap: () {
              context.read<BenchmarkBloc>().add(
                    ToggleMovieExpanded(movieId: movie.id),
                  );
            },
          );
        },
      );
    }
  }

  Widget _buildEnrichedMovieView(BenchmarkState state) {
    UIPerformanceTracker.markWidgetRebuild(); // ZMIANA - usunięto parametr
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.enrichedMovies.length,
      itemBuilder: (context, index) {
        final enrichedMovie = state.enrichedMovies[index];
        return Card(
          child: ListTile(
            title: Text(enrichedMovie.baseMovie.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cast: ${enrichedMovie.cast.take(3).join(", ")}...'),
                Text('Reviews: ${enrichedMovie.reviews.length}'),
                Text(
                    'Progress: ${(enrichedMovie.watchProgress * 100).toStringAsFixed(1)}%'),
              ],
            ),
            trailing: Column(
              children: [
                Icon(enrichedMovie.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border),
                Icon(enrichedMovie.isInWatchlist
                    ? Icons.bookmark
                    : Icons.bookmark_border),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHighFrequencyView(BenchmarkState state) {
    UIPerformanceTracker.markWidgetRebuild(); // ZMIANA - usunięto parametr
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Frame: ${state.progressCounter}',
              style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: state.multiCounters.length,
              itemBuilder: (context, index) {
                return Card(
                  color: state.loadingStates.length > index &&
                          state.loadingStates[index]
                      ? Colors.blue.withOpacity(0.3)
                      : null,
                  child: Center(
                    child: Text(
                      '${state.multiCounters[index]}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getScenarioName(ScenarioType type) {
    switch (type) {
      case ScenarioType.apiStreaming:
        return 'S01 - API Streaming';
      case ScenarioType.realtimeFiltering:
        return 'S02 - Real-time Filtering';
      case ScenarioType.memoryPressure:
        return 'S03 - Memory Pressure';
      case ScenarioType.cascadingUpdates:
        return 'S04 - Cascading Updates';
      case ScenarioType.highFrequency:
        return 'S05 - High Frequency';
    }
  }
}
