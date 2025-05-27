import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/theme/bloc/theme_block.dart';
import '../../../../../core/widgets/movie_list_item.dart';
import '../../../../../core/widgets/movie_grid_item.dart';
import '../widgets/bloc_benchmark_controls.dart';
import '../../../theme/bloc/theme_event.dart';
import '../../bloc/benchmark_bloc.dart';
import '../../bloc/benchmark_event.dart';
import '../../bloc/benchmark_state.dart';

class BlocBenchmarkPage extends StatelessWidget {
  final String scenarioId;
  final int dataSize;

  const BlocBenchmarkPage({
    super.key,
    required this.scenarioId,
    required this.dataSize,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => BenchmarkBloc(
            apiClient: context.read<TmdbApiClient>(),
          )..add(StartBenchmark(scenarioId: scenarioId, dataSize: dataSize)),
        ),
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
      ],
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
                backgroundColor: Colors.blue,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('BLoC Benchmark: $scenarioId'),
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
                  BlocBenchmarkControls(
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
        controller: scrollController,
        padding: const EdgeInsets.all(8),
        itemCount: state.filteredMovies.length,
        itemBuilder: (context, index) {
          final movie = state.filteredMovies[index];

          if (state.scenarioId == 'S02' &&
              index == state.filteredMovies.length - 5 &&
              state.loadedCount < state.dataSize) {
            context.read<BenchmarkBloc>().add(LoadMoreMovies());
          }

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
}
