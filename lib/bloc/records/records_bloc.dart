import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../repositories/records_repository.dart';
import '../../models/visit_model.dart';
import '../../models/user_model.dart';
part 'records_event.dart';
part 'records_state.dart';

class RecordsBloc extends Bloc<RecordsEvent, RecordsState> {
  final RecordsRepository _recordsRepository;

  RecordsBloc({required RecordsRepository recordsRepository})
    : _recordsRepository = recordsRepository,
      super(const RecordsState()) {
    on<RecordsLoadRequested>(_onLoadRequested);
    on<RecordsCreatePatientCard>(_onCreatePatientCard);
  }

  Future<void> _onLoadRequested(
    RecordsLoadRequested event,
    Emitter<RecordsState> emit,
  ) async {
    emit(state.copyWith(status: RecordsStatus.loading));

    try {
      List<VisitModel> visits;
      if (event.userRole == UserRole.doctor) {
        visits = await _recordsRepository.getDoctorVisits(event.userId);
      } else {
        visits = await _recordsRepository.getPatientVisits(event.userId);
      }

      emit(state.copyWith(status: RecordsStatus.success, visits: visits));
    } catch (e) {
      emit(
        state.copyWith(
          status: RecordsStatus.failure,
          errorMessage: 'Ошибка загрузки записей: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onCreatePatientCard(
    RecordsCreatePatientCard event,
    Emitter<RecordsState> emit,
  ) async {
    try {
      await _recordsRepository.createPatientCard(
        patientId: event.patientId,
        diagnosis: event.diagnosis,
        recommendation: event.recommendation,
      );
      // Перезагружаем записи доктора, а не пациента
      add(
        RecordsLoadRequested(
          userId: event.doctorId, // <<< ID доктора
          userRole: UserRole.doctor,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RecordsStatus.failure,
          errorMessage: 'Ошибка создания карточки: ${e.toString()}',
        ),
      );
    }
  }
}
