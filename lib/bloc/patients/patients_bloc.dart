import 'package:clinic_app/models/user_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/user_repository.dart';
part 'patients_event.dart';
part 'patients_state.dart';

class PatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  final UserRepository _userRepository;

  PatientsBloc({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(const PatientsState()) {
    on<PatientsLoadRequested>(_onLoadRequested);
    on<PatientsSearchChanged>(_onSearchChanged);
    on<PatientUpdateRequested>(_onUpdateRequested);
    on<PatientDeactivateRequested>(_onDeactivateRequested);
    on<PatientsStateReset>(_onStateReset);
  }

  Future<void> _onLoadRequested(
    PatientsLoadRequested event,
    Emitter<PatientsState> emit,
  ) async {
    emit(state.copyWith(status: PatientsStatus.loading, errorMessage: null));

    try {
      final patients = await _userRepository.getPatients();
      emit(
        state.copyWith(
          status: PatientsStatus.success,
          patients: patients,
          filteredPatients: _filterPatients(patients, state.searchQuery),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PatientsStatus.failure,
          errorMessage: 'Ошибка загрузки пациентов: ${e.toString()}',
        ),
      );
    }
  }

  void _onSearchChanged(
    PatientsSearchChanged event,
    Emitter<PatientsState> emit,
  ) {
    final filteredPatients = _filterPatients(state.patients, event.query);

    emit(
      state.copyWith(
        searchQuery: event.query,
        filteredPatients: filteredPatients,
      ),
    );
  }

  Future<void> _onUpdateRequested(
    PatientUpdateRequested event,
    Emitter<PatientsState> emit,
  ) async {
    // ✅ Эмитим loading состояние
    emit(state.copyWith(status: PatientsStatus.loading, errorMessage: null));

    try {
      final updatedPatient = await _userRepository.updateUser(event.patient);

      // ✅ Создаем НОВЫЙ список (важно!)
      final updatedPatients = state.patients.map((patient) {
        return patient.id == updatedPatient.id ? updatedPatient : patient;
      }).toList();

      // ✅ Создаем новые копии списков
      final newFilteredPatients = _filterPatients(
        updatedPatients,
        state.searchQuery,
      );

      // ✅ Эмитим success состояние с новыми списками
      emit(
        state.copyWith(
          status: PatientsStatus.success,
          patients: List.from(updatedPatients), // Новая копия
          filteredPatients: List.from(newFilteredPatients), // Новая копия
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PatientsStatus.failure,
          errorMessage: 'Ошибка обновления пациента: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeactivateRequested(
    PatientDeactivateRequested event,
    Emitter<PatientsState> emit,
  ) async {
    // ✅ Эмитим loading состояние
    emit(state.copyWith(status: PatientsStatus.loading, errorMessage: null));

    try {
      await _userRepository.deactivateUser(event.patientId);

      // ✅ Создаем НОВЫЙ список без деактивированного пациента
      final updatedPatients = state.patients
          .where((patient) => patient.id != event.patientId)
          .toList();

      final newFilteredPatients = _filterPatients(
        updatedPatients,
        state.searchQuery,
      );

      // ✅ Эмитим success состояние с новыми списками
      emit(
        state.copyWith(
          status: PatientsStatus.success,
          patients: List.from(updatedPatients), // Новая копия
          filteredPatients: List.from(newFilteredPatients), // Новая копия
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PatientsStatus.failure,
          errorMessage: 'Ошибка деактивации пациента: ${e.toString()}',
        ),
      );
    }
  }

  // Добавьте метод для сброса состояния
  void _onStateReset(PatientsStateReset event, Emitter<PatientsState> emit) {
    emit(state.copyWith(status: PatientsStatus.initial, errorMessage: null));
  }

  // Вспомогательный метод для фильтрации
  List<UserModel> _filterPatients(List<UserModel> patients, String query) {
    if (query.isEmpty) return patients;

    final searchQuery = query.toLowerCase();
    return patients.where((patient) {
      final fullName = patient.fullName.toLowerCase();
      return fullName.contains(searchQuery);
    }).toList();
  }
}
