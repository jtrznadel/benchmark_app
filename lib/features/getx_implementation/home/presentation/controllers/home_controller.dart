import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class HomeController extends GetxController {
  final selectedScenario =
      Rx<ScenarioType?>(null); // ZMIANA: String? -> ScenarioType?
  final dataSize = 1000.obs; // ZMIANA: 500 -> 1000

  void selectScenario(ScenarioType scenario, int size) {
    // ZMIANA: String -> ScenarioType
    selectedScenario.value = scenario;
    dataSize.value = size;
  }
}
