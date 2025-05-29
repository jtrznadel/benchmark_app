import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:moviedb_benchmark/core/api/tmdb_api__client.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/theme/bloc/theme_block.dart';
import '../../../../../core/widgets/movie_list_item.dart';
import '../../../../../core/widgets/movie_grid_item.dart';
import '../widgets/bloc_benchmark_controls.dart';
import '../../../theme/bloc/theme_event.dart';
import '../../bloc/benchmark_bloc.dart';
import '../../bloc/benchmark_event.dart';
import '../../bloc/benchmark_state.dart';

class BlocBenchmarkPage extends StatefulWidget {
  final String scenarioId;
  final int dataSize;

  const BlocBenchmarkPage({
    super.key,
    required this.scenarioId,
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
              scenarioId: widget.scenarioId, dataSize: widget.dataSize)),
        ),
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
      ],
      child: _BlocBenchmarkPageContent(
        scenarioId: widget.scenarioId,
        dataSize: widget.dataSize,
      ),
    );
  }
}

class _BlocBenchmarkPageContent extends StatefulWidget {
  final String scenarioId;
  final int dataSize;

  const _BlocBenchmarkPageContent({
    required this.scenarioId,
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
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !_scrollController.hasClients) {
        timer.cancel();
        return;
      }

      final bloc = context.read<BenchmarkBloc>();
      final state = bloc.state;

      if (!state.isAutoScrolling || state.status == BenchmarkStatus.completed) {
        timer.cancel();
        return;
      }

      final currentPosition = _scrollController.position.pixels;
      final maxScroll = _scrollController.position.maxScrollExtent;

      // Przewijamy o 100 pikseli na raz
      final newPosition = currentPosition + 100;

      if (newPosition >= maxScroll && state.loadedCount >= widget.dataSize) {
        timer.cancel();
        bloc.add(BenchmarkCompleted());
      } else if (newPosition <= maxScroll) {
        _scrollController.jumpTo(newPosition);
      } else if (maxScroll > currentPosition) {
        _scrollController.jumpTo(maxScroll);
      }
    });
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

        if (widget.scenarioId == 'S02' &&
            state.isAutoScrolling &&
            state.status == BenchmarkStatus.running) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoScroll();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('BLoC Benchmark: ${widget.scenarioId}'),
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
                  scenarioId: widget.scenarioId,
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
    if (state.filteredMovies.isEmpty) {
      return const Center(child: Text('Brak filmów do wyświetlenia'));
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

          if (state.scenarioId == 'S02' &&
              index == state.filteredMovies.length - 10 &&
              state.loadedCount < state.dataSize &&
              !context.read<BenchmarkBloc>().isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<BenchmarkBloc>().add(LoadMoreMovies());
            });
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
