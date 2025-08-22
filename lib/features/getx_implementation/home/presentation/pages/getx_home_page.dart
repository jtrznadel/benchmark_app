import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';
import 'package:moviedb_benchmark/features/getx_implementation/benchmark/presentation/pages/getx_benchmark._page.dart';
import 'package:moviedb_benchmark/features/getx_implementation/home/presentation/controllers/home_controller.dart';
import '../widgets/getx_scenario_selector.dart';
import '../../../theme/controllers/theme_controller.dart';

class GetXHomePage extends StatelessWidget {
  const GetXHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ThemeController());
    final homeController = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('MovieDB Benchmark - GetX'),
        backgroundColor: Colors.purple,
      ),
      body: Obx(() => Padding(
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
                  child: GetXScenarioSelector(
                    selectedScenario: homeController.selectedScenario.value,
                    dataSize: homeController.dataSize.value,
                    selectedStressLevel:
                        homeController.selectedStressLevel.value,
                    onScenarioSelected: (scenario, size,
                        {TestStressLevel? stressLevel}) {
                      // ZMIENIONE sygnaturę
                      homeController.selectScenario(scenario, size,
                          stressLevel: stressLevel);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: homeController.selectedScenario.value != null
                      ? () {
                          Get.to(() => GetXBenchmarkPage(
                                scenarioType:
                                    homeController.selectedScenario.value!,
                                dataSize: homeController.dataSize.value,
                                stressLevel: homeController
                                    .selectedStressLevel.value, // DODANE
                              ));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Start testu',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
