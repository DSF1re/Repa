part of 'schedule_bloc.dart';

enum ScheduleStatus { initial, loading, success, failure }

class ScheduleState extends Equatable {
  final ScheduleStatus status;
  final List<Map<String, dynamic>> schedules;
  final List<Map<String, dynamic>> filteredSchedules;
  final String searchQuery;
  final DateTime? selectedDate;
  final String? errorMessage;

  const ScheduleState({
    this.status = ScheduleStatus.initial,
    this.schedules = const [],
    this.filteredSchedules = const [],
    this.searchQuery = '',
    this.selectedDate,
    this.errorMessage,
  });

  ScheduleState copyWith({
    ScheduleStatus? status,
    List<Map<String, dynamic>>? schedules,
    List<Map<String, dynamic>>? filteredSchedules,
    String? searchQuery,
    DateTime? selectedDate,
    String? errorMessage,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      schedules: schedules ?? this.schedules,
      filteredSchedules: filteredSchedules ?? this.filteredSchedules,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    schedules,
    filteredSchedules,
    searchQuery,
    selectedDate,
    errorMessage,
  ];
}
