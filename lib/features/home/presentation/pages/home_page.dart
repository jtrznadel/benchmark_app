import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark_bloc/features/home/presentation/pages/widgets/scenario_selector.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../../../benchmark/presentation/pages/benchmark_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieDB Benchmark - BLoC'),
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Wybierz scenariusz testowy:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ScenarioSelector(
                  selectedScenario: state.selectedScenario,
                  dataSize: state.dataSize,
                  onScenarioSelected: (scenario, size) {
                    context.read<HomeBloc>().add(
                          SelectScenario(
                            scenarioId: scenario,
                            dataSize: size,
                          ),
                        );
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: state.selectedScenario != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BenchmarkPage(
                                scenarioId: state.selectedScenario!,
                                dataSize: state.dataSize,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text(
                    'Start testu',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
