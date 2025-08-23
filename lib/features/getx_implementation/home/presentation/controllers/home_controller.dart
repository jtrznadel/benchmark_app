import 'package:get/get.dart';
import 'package:moviedb_benchmark/core/utils/enums.dart';

class HomeController extends GetxController {
  final selectedScenario = Rx<ScenarioType?>(null);
  final dataSize = 1000.obs;

  void selectScenario(ScenarioType scenario, int size) {
    selectedScenario.value = scenario;
    dataSize.value = size;
  }
}
