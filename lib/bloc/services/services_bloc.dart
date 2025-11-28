import 'package:clinic_app/models/service_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/service_repository.dart';
part 'services_event.dart';
part 'services_state.dart';

class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final ServiceRepository _serviceRepository;

  ServicesBloc({required ServiceRepository serviceRepository})
    : _serviceRepository = serviceRepository,
      super(const ServicesState()) {
    on<ServicesLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ServicesLoadRequested event,
    Emitter<ServicesState> emit,
  ) async {
    emit(state.copyWith(status: ServicesStatus.loading));

    try {
      final services = await _serviceRepository.getServices();
      emit(state.copyWith(status: ServicesStatus.success, services: services));
    } catch (e) {
      emit(
        state.copyWith(
          status: ServicesStatus.failure,
          errorMessage: 'Ошибка загрузки услуг: ${e.toString()}',
        ),
      );
    }
  }
}
