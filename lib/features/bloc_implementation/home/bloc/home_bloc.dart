import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<SelectScenario>(_onSelectScenario);
  }

  void _onSelectScenario(SelectScenario event, Emitter<HomeState> emit) {
    emit(state.copyWith(
      selectedScenario: event.scenarioType,
      dataSize: event.dataSize,
      selectedStressLevel: event.stressLevel, // DODANE
    ));
  }
}
