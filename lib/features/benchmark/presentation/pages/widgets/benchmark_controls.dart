import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark_bloc/features/benchmark/bloc/benchmark_bloc.dart';
import 'package:moviedb_benchmark_bloc/features/benchmark/bloc/benchmark_event.dart';
import 'package:moviedb_benchmark_bloc/features/benchmark/bloc/benchmark_state.dart';

class BenchmarkControls extends StatelessWidget {
  final String scenarioId;
  final BenchmarkState state;

  const BenchmarkControls({
    super.key,
    required this.scenarioId,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Status: ${_getStatusText(state.status)}'),
              Text('Załadowano: ${state.loadedCount}/${state.dataSize}'),
            ],
          ),
          if (scenarioId == 'S03' && state.status == BenchmarkStatus.running)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<BenchmarkBloc>().add(
                          const FilterMovies(genreIds: [28]), // Action
                        );
                  },
                  child: const Text('Filtruj: Akcja'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<BenchmarkBloc>().add(
                          const SortMovies(byReleaseDate: true),
                        );
                  },
                  child: const Text('Sortuj: Data'),
                ),
              ],
            ),
          if (scenarioId == 'S05' && state.status == BenchmarkStatus.running)
            ElevatedButton(
              onPressed: () {
                context.read<BenchmarkBloc>().add(ToggleAccessibilityMode());
              },
              child: Text(
                state.isAccessibilityMode
                    ? 'Wyłącz tryb dostępności'
                    : 'Włącz tryb dostępności',
              ),
            ),
        ],
      ),
    );
  }

  String _getStatusText(BenchmarkStatus status) {
    switch (status) {
      case BenchmarkStatus.initial:
        return 'Początkowy';
      case BenchmarkStatus.loading:
        return 'Ładowanie';
      case BenchmarkStatus.loaded:
        return 'Załadowano';
      case BenchmarkStatus.running:
        return 'W trakcie';
      case BenchmarkStatus.completed:
        return 'Zakończony';
      case BenchmarkStatus.error:
        return 'Błąd';
    }
  }
}
