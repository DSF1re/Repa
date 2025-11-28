import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/schedule_repository.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository _scheduleRepository;

  ScheduleBloc({required ScheduleRepository scheduleRepository})
    : _scheduleRepository = scheduleRepository,
      super(const ScheduleState()) {
    on<ScheduleLoadRequested>(_onLoadRequested);
    on<ScheduleSearchChanged>(_onSearchChanged);
    on<ScheduleDateFilterChanged>(_onDateFilterChanged);
    on<ScheduleAddRequested>(_onAddRequested);
    on<ScheduleDeleteRequested>(_onDeleteRequested);
    on<ScheduleStateReset>(_onStateReset);
  }

  Future<void> _onLoadRequested(
    ScheduleLoadRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(state.copyWith(status: ScheduleStatus.loading, errorMessage: null));

    try {
      final schedules = await _scheduleRepository.getSchedules();
      emit(
        state.copyWith(
          status: ScheduleStatus.success,
          schedules: schedules,
          filteredSchedules: _filterSchedules(
            schedules,
            state.searchQuery,
            state.selectedDate,
          ),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ScheduleStatus.failure,
          errorMessage: 'Ошибка загрузки расписания: ${e.toString()}',
        ),
      );
    }
  }

  void _onStateReset(ScheduleStateReset event, Emitter<ScheduleState> emit) {
    emit(state.copyWith(status: ScheduleStatus.initial, errorMessage: null));
  }

  void _onSearchChanged(
    ScheduleSearchChanged event,
    Emitter<ScheduleState> emit,
  ) {
    final filteredSchedules = _filterSchedules(
      state.schedules,
      event.query,
      state.selectedDate,
    );

    emit(
      state.copyWith(
        searchQuery: event.query,
        filteredSchedules: filteredSchedules,
      ),
    );
  }

  void _onDateFilterChanged(
    ScheduleDateFilterChanged event,
    Emitter<ScheduleState> emit,
  ) {
    final filteredSchedules = _filterSchedules(
      state.schedules,
      state.searchQuery,
      event.date,
    );

    emit(
      state.copyWith(
        selectedDate: event.date,
        filteredSchedules: filteredSchedules,
      ),
    );
  }

  Future<void> _onAddRequested(
    ScheduleAddRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(state.copyWith(status: ScheduleStatus.loading, errorMessage: null));

    try {
      await _scheduleRepository.addSchedule(event.scheduleData);

      final schedules = await _scheduleRepository.getSchedules();
      emit(
        state.copyWith(
          status: ScheduleStatus.success,
          schedules: schedules,
          filteredSchedules: _filterSchedules(
            schedules,
            state.searchQuery,
            state.selectedDate,
          ),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ScheduleStatus.failure,
          errorMessage: 'Ошибка добавления расписания: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    ScheduleDeleteRequested event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(state.copyWith(status: ScheduleStatus.loading, errorMessage: null));

    try {
      await _scheduleRepository.deleteSchedule(event.scheduleId);

      // Обновляем локальный список
      final updatedSchedules = state.schedules
          .where((s) => s['ID_Schedule'] != event.scheduleId)
          .toList();

      emit(
        state.copyWith(
          status: ScheduleStatus.success,
          schedules: List.from(updatedSchedules),
          filteredSchedules: _filterSchedules(
            updatedSchedules,
            state.searchQuery,
            state.selectedDate,
          ),
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ScheduleStatus.failure,
          errorMessage: 'Ошибка удаления расписания: ${e.toString()}',
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterSchedules(
    List<Map<String, dynamic>> schedules,
    String query,
    DateTime? selectedDate,
  ) {
    var filtered = schedules;

    // Фильтрация по дате
    if (selectedDate != null) {
      final dateStr = selectedDate.toIso8601String().substring(0, 10);
      filtered = filtered.where((schedule) {
        final scheduleDate = schedule['Date'] ?? '';
        return scheduleDate.toString().contains(dateStr);
      }).toList();
    }

    // Фильтрация по поисковому запросу
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      filtered = filtered.where((schedule) {
        final doctor = schedule['User'] ?? {};
        final cabinet = schedule['Cabinet'] ?? {};

        final surname = doctor['Surname'] ?? '';
        final name = doctor['Name'] ?? '';
        final patronymic = doctor['Patronymic'] ?? '';
        final specialization = doctor['Specialization'] ?? '';
        final fullName = '$surname $name $patronymic'.toLowerCase();
        final cabinetName = cabinet['Name'] ?? ''.toLowerCase();

        final startTime = schedule['Time_Start'] ?? '';
        final endTime = schedule['Time_End'] ?? '';
        final timeMatch = '$startTime-$endTime'.toLowerCase();

        return fullName.contains(queryLower) ||
            specialization.toLowerCase().contains(queryLower) ||
            cabinetName.contains(queryLower) ||
            timeMatch.contains(queryLower);
      }).toList();
    }

    return filtered;
  }
}
