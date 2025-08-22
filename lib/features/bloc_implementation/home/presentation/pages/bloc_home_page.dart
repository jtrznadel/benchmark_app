import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/features/bloc_implementation/home/presentation/pages/widgets/bloc_scenario_selector.dart';
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
                Expanded(
                  child: BlocScenarioSelector(
                    selectedScenario: state.selectedScenario,
                    dataSize: state.dataSize,
                    selectedStressLevel: state.selectedStressLevel,
                    onScenarioSelected: (scenario, size,
                        {TestStressLevel? stressLevel}) {
                      // ZMIENIONE sygnaturę
                      context.read<HomeBloc>().add(
                            SelectScenario(
                              scenarioType: scenario,
                              dataSize: size,
                              stressLevel: stressLevel,
                            ),
                          );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.selectedScenario != null
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlocBenchmarkPage(
                                scenarioType: state.selectedScenario!,
                                dataSize: state.dataSize,
                                stressLevel:
                                    state.selectedStressLevel, // DODANE
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
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
