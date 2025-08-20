import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/core/utils/uip_tracker.dart';
import 'dart:async';
import 'package:moviedb_benchmark/features/getx_implementation/benchmark/presentation/controllers/benchmark_controller.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/benchmark/bloc/benchmark_state.dart';
import '../widgets/getx_benchmark_controls.dart';
import '../../../../../core/widgets/movie_list_item.dart';
import '../../../../../core/widgets/movie_grid_item.dart';

class GetXBenchmarkPage extends StatefulWidget {
  final ScenarioType scenarioType;
  final int dataSize;

  const GetXBenchmarkPage({
    super.key,
    required this.scenarioType,
    required this.dataSize,
  });

  @override
  State<GetXBenchmarkPage> createState() => _GetXBenchmarkPageState();
}

class _GetXBenchmarkPageState extends State<GetXBenchmarkPage> {
  late ScrollController _scrollController;
  final controller = Get.put(BenchmarkController());

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    UIPerformanceTracker.startTracking(); // ZMIANA

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.startBenchmark(widget.scenarioType, widget.dataSize);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    UIPerformanceTracker.stopTracking(); // ZMIANA
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GetX Benchmark: ${_getScenarioName(widget.scenarioType)}'),
        backgroundColor: Colors.purple,
        actions: [
          Obx(() {
            if (controller.status.value == BenchmarkStatus.running ||
                controller.status.value == BenchmarkStatus.loaded) {
              return IconButton(
                icon: Icon(
                  controller.viewMode.value == ViewMode.list
                      ? Icons.grid_view
                      : Icons.list,
                ),
                onPressed: controller.toggleViewMode,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
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
              child: _buildMovieView(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMovieView() {
    return Obx(() {
      // For scenarios that use enriched movies, show those
      if (controller.enrichedMovies.isNotEmpty) {
        return _buildEnrichedMovieView();
      }

      // For high frequency scenario, show counters
      if (widget.scenarioType == ScenarioType.highFrequency) {
        return _buildHighFrequencyView();
      }

      // Default movie view
      if (controller.filteredMovies.isEmpty) {
        return const Center(child: Text('No movies to display'));
      }

      if (controller.viewMode.value == ViewMode.grid) {
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: controller.filteredMovies.length,
          itemBuilder: (context, index) {
            final movie = controller.filteredMovies[index];
            return Obx(() => MovieGridItem(
                  movie: movie,
                  isExpanded: controller.expandedMovies.contains(movie.id),
                  isAccessibilityMode: controller.isAccessibilityMode.value,
                  onTap: () => controller.toggleMovieExpanded(movie.id),
                ));
          },
        );
      } else {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          itemCount: controller.filteredMovies.length,
          itemBuilder: (context, index) {
            final movie = controller.filteredMovies[index];
            return MovieListItem(
              movie: movie,
              isExpanded: controller.expandedMovies.contains(movie.id),
              isAccessibilityMode: controller.isAccessibilityMode.value,
              onTap: () {
                controller.toggleMovieExpanded(movie.id);
              },
            );
          },
        );
      }
    });
  }

  Widget _buildEnrichedMovieView() {
    UIPerformanceTracker.markWidgetRebuild(); // ZMIANA - usunięto parametr
    return Obx(() => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: controller.enrichedMovies.length,
          itemBuilder: (context, index) {
            final enrichedMovie = controller.enrichedMovies[index];
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
        ));
  }

  Widget _buildHighFrequencyView() {
    UIPerformanceTracker.markWidgetRebuild(); // ZMIANA - usunięto parametr
    return Obx(() => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('Frame: ${controller.progressCounter.value}',
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
                  itemCount: controller.multiCounters.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: controller.loadingStates.length > index &&
                              controller.loadingStates[index]
                          ? Colors.purple.withOpacity(0.3)
                          : null,
                      child: Center(
                        child: Text(
                          '${controller.multiCounters[index]}',
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
        ));
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
