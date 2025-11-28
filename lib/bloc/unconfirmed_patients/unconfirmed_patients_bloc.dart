import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/user_repository.dart';

part 'unconfirmed_patients_event.dart';
part 'unconfirmed_patients_state.dart';

class UnconfirmedPatientsBloc
    extends Bloc<UnconfirmedPatientsEvent, UnconfirmedPatientsState> {
  final UserRepository _userRepository;

  UnconfirmedPatientsBloc({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(const UnconfirmedPatientsState()) {
    on<UnconfirmedPatientsLoadRequested>(_onLoadRequested);
    on<PatientConfirmRequested>(_onConfirmRequested);
    on<PatientRejectRequested>(_onRejectRequested);
    on<UnconfirmedPatientsStateReset>(_onStateReset);
  }

  Future<void> _onLoadRequested(
    UnconfirmedPatientsLoadRequested event,
    Emitter<UnconfirmedPatientsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UnconfirmedPatientsStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final patients = await _userRepository.getUnconfirmedPatientsAsMap();
      emit(
        state.copyWith(
          status: UnconfirmedPatientsStatus.success,
          patients: patients,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UnconfirmedPatientsStatus.failure,
          errorMessage: 'Ошибка загрузки пациентов: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onConfirmRequested(
    PatientConfirmRequested event,
    Emitter<UnconfirmedPatientsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UnconfirmedPatientsStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      await _userRepository.confirmPatient(event.patientId);

      final updatedPatients = state.patients
          .where((p) => p['ID_User'] != event.patientId)
          .toList();

      emit(
        state.copyWith(
          status: UnconfirmedPatientsStatus.success,
          patients: List.from(updatedPatients),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UnconfirmedPatientsStatus.failure,
          errorMessage: 'Ошибка подтверждения пациента: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onRejectRequested(
    PatientRejectRequested event,
    Emitter<UnconfirmedPatientsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: UnconfirmedPatientsStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      await _userRepository.rejectPatient(event.patientId);

      final updatedPatients = state.patients
          .where((p) => p['ID_User'] != event.patientId)
          .toList();

      emit(
        state.copyWith(
          status: UnconfirmedPatientsStatus.success,
          patients: List.from(updatedPatients),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UnconfirmedPatientsStatus.failure,
          errorMessage: 'Ошибка отклонения пациента: ${e.toString()}',
        ),
      );
    }
  }

  void _onStateReset(
    UnconfirmedPatientsStateReset event,
    Emitter<UnconfirmedPatientsState> emit,
  ) {
    emit(
      state.copyWith(
        status: UnconfirmedPatientsStatus.initial,
        errorMessage: null,
      ),
    );
  }
}
