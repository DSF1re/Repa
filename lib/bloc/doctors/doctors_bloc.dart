import 'package:clinic_app/models/user_model.dart';
import 'package:clinic_app/repositories/doctors_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/user_repository.dart';

part 'doctors_event.dart';
part 'doctors_state.dart';

class DoctorsBloc extends Bloc<DoctorsEvent, DoctorsState> {
  final UserRepository _userRepository;

  DoctorsBloc({
    required UserRepository userRepository,
    required DoctorsRepository doctorsRepository,
  }) : _userRepository = userRepository,
       super(const DoctorsState()) {
    on<DoctorsLoadRequested>(_onLoadRequested);
    on<DoctorsSearchChanged>(_onSearchChanged);
    on<DoctorUpdateRequested>(_onUpdateRequested);
    on<DoctorDeactivateRequested>(_onDeactivateRequested);
    on<DoctorsStateReset>(_onStateReset);
  }

  Future<void> _onLoadRequested(
    DoctorsLoadRequested event,
    Emitter<DoctorsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DoctorsStatus.loading,
        errorMessage: null, // ✅ Сброс ошибки
      ),
    );

    try {
      final doctors = await _userRepository.getDoctors();
      emit(
        state.copyWith(
          status: DoctorsStatus.success,
          doctors: doctors,
          filteredDoctors: _filterDoctors(doctors, state.searchQuery),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DoctorsStatus.failure,
          errorMessage: 'Ошибка загрузки врачей: ${e.toString()}',
        ),
      );
    }
  }

  void _onSearchChanged(
    DoctorsSearchChanged event,
    Emitter<DoctorsState> emit,
  ) {
    final filteredDoctors = _filterDoctors(state.doctors, event.query);

    emit(
      state.copyWith(
        searchQuery: event.query,
        filteredDoctors: filteredDoctors,
      ),
    );
  }

  Future<void> _onUpdateRequested(
    DoctorUpdateRequested event,
    Emitter<DoctorsState> emit,
  ) async {
    emit(state.copyWith(status: DoctorsStatus.loading, errorMessage: null));

    try {
      final updatedDoctor = await _userRepository.updateUser(event.doctor);

      final updatedDoctors = state.doctors.map((doctor) {
        return doctor.id == updatedDoctor.id ? updatedDoctor : doctor;
      }).toList();

      final newFilteredDoctors = _filterDoctors(
        updatedDoctors,
        state.searchQuery,
      );

      emit(
        state.copyWith(
          status: DoctorsStatus.success,
          doctors: List<UserModel>.from(updatedDoctors),
          filteredDoctors: List<UserModel>.from(newFilteredDoctors),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DoctorsStatus.failure,
          errorMessage: 'Ошибка обновления врача: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeactivateRequested(
    DoctorDeactivateRequested event,
    Emitter<DoctorsState> emit,
  ) async {
    emit(state.copyWith(status: DoctorsStatus.loading, errorMessage: null));

    try {
      await _userRepository.deactivateUser(event.doctorId);

      final updatedDoctors = state.doctors
          .where((doctor) => doctor.id != event.doctorId)
          .toList();

      final newFilteredDoctors = _filterDoctors(
        updatedDoctors,
        state.searchQuery,
      );

      emit(
        state.copyWith(
          status: DoctorsStatus.success,
          doctors: List<UserModel>.from(updatedDoctors),
          filteredDoctors: List<UserModel>.from(newFilteredDoctors),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DoctorsStatus.failure,
          errorMessage: 'Ошибка деактивации врача: ${e.toString()}',
        ),
      );
    }
  }

  void _onStateReset(DoctorsStateReset event, Emitter<DoctorsState> emit) {
    emit(state.copyWith(status: DoctorsStatus.initial, errorMessage: null));
  }

  List<UserModel> _filterDoctors(List<UserModel> doctors, String query) {
    if (query.isEmpty) return doctors;

    final searchQuery = query.toLowerCase();
    return doctors.where((doctor) {
      final fullName = doctor.fullName.toLowerCase();
      return fullName.contains(searchQuery);
    }).toList();
  }
}
