import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/benchmark_bloc.dart';
import '../../bloc/benchmark_event.dart';
import '../../bloc/benchmark_state.dart';

class BlocBenchmarkControls extends StatelessWidget {
  final String scenarioId;
  final BenchmarkState state;

  const BlocBenchmarkControls({
    super.key,
    required this.scenarioId,
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
                          const FilterMovies(genreIds: [28]), // action
                        );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Filtruj: Akcja'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.read<BenchmarkBloc>().add(
                          const SortMovies(byReleaseDate: true),
                        );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('Sortuj: Data'),
                ),
              ],
            ),
          if (scenarioId == 'S05' && state.status == BenchmarkStatus.running)
            ElevatedButton(
              onPressed: () {
                context.read<BenchmarkBloc>().add(ToggleAccessibilityMode());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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