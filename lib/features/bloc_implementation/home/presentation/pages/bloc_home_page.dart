import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/bloc_scenario_selector.dart';
import '../../bloc/home_bloc.dart';
import '../../bloc/home_event.dart';
import '../../bloc/home_state.dart';
import '../../../benchmark/presentation/pages/bloc_benchmark_page.dart';

class BlocHomePage extends StatelessWidget {
  const BlocHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieDB Benchmark - BLoC'),
        backgroundColor: Colors.blue,
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
                BlocScenarioSelector(
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
                              builder: (context) => BlocBenchmarkPage(
                                scenarioId: state.selectedScenario!,
                                dataSize: state.dataSize,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
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