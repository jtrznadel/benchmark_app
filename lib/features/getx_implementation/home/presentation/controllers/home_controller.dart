import 'package:get/get.dart';

class HomeController extends GetxController {
  final selectedScenario = Rx<String?>(null);
  final dataSize = 500.obs;

  void selectScenario(String scenario, int size) {
    selectedScenario.value = scenario;
    dataSize.value = size;
  }
}