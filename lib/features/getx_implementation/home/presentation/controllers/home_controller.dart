import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class HomeController extends GetxController {
  final selectedScenario = Rx<ScenarioType?>(null);
  final dataSize = 1000.obs;
  final selectedStressLevel = Rx<TestStressLevel?>(null); // DODANE

  void selectScenario(ScenarioType scenario, int size,
      {TestStressLevel? stressLevel}) {
    // ZMIENIONE
    selectedScenario.value = scenario;
    dataSize.value = size;
    selectedStressLevel.value = stressLevel; // DODANE
  }
}
