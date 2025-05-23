import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark_bloc/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark_bloc/features/benchmark/presentation/pages/widgets/benchmark_controls.dart';
import 'package:moviedb_benchmark_bloc/features/benchmark/presentation/pages/widgets/movie_grid_item.dart';
import 'package:moviedb_benchmark_bloc/features/benchmark/presentation/pages/widgets/movie_list_item.dart';

import '../../../theme/bloc/theme_bloc.dart';
import '../../../theme/bloc/theme_event.dart';
import '../../bloc/benchmark_bloc.dart';
import '../../bloc/benchmark_event.dart';
import '../../bloc/benchmark_state.dart';

class BenchmarkPage extends StatelessWidget {
  final String scenarioId;
  final int dataSize;

  const BenchmarkPage({
    super.key,
    required this.scenarioId,
    required this.dataSize,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BenchmarkBloc(
        apiClient: context.read<TmdbApiClient>(),
      )..add(StartBenchmark(scenarioId: scenarioId, dataSize: dataSize)),
      child: BlocListener<BenchmarkBloc, BenchmarkState>(
        listener: (context, state) {
          if (state.isAccessibilityMode) {
            context.read<ThemeBloc>().add(EnableAccessibilityTheme());
          } else {
            context.read<ThemeBloc>().add(DisableAccessibilityTheme());
          }

          if (state.status == BenchmarkStatus.completed) {
            final duration = state.endTime!.difference(state.startTime!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Test zakończony! Czas: ${duration.inSeconds}.${duration.inMilliseconds % 1000} s',
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Benchmark: $scenarioId'),
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
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Ładowanie danych...'),
                    ],
                  ),
                );
              }

              if (state.status == BenchmarkStatus.error) {
                return Center(
                  child: Text(
                    'Błąd: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              return Column(
                children: [
                  BenchmarkControls(
                    scenarioId: scenarioId,
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
      ),
    );
  }

  Widget _buildMovieView(BuildContext context, BenchmarkState state) {
    if (state.filteredMovies.isEmpty) {
      return const Center(child: Text('Brak filmów do wyświetlenia'));
    }

    final scrollController = ScrollController();

    // Automatyczne przewijanie dla S02
    if (state.scenarioId == 'S02' && state.isAutoScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(seconds: 2),
            curve: Curves.linear,
          );
        }
      });
    }

    if (state.viewMode == ViewMode.grid) {
      return GridView.builder(
        controller: scrollController,
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
        controller: scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: state.filteredMovies.length,
        itemBuilder: (context, index) {
          final movie = state.filteredMovies[index];

          // Dla S02 - sprawdź czy trzeba załadować więcej
          if (state.scenarioId == 'S02' &&
              index == state.filteredMovies.length - 5 &&
              state.loadedCount < state.dataSize) {
            context.read<BenchmarkBloc>().add(LoadMoreMovies());
          }

          return MovieListItem(
            movie: movie,
            isExpanded: state.expandedMovies.contains(movie.id),
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
}
