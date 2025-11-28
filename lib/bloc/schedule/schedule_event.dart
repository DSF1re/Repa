part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

class ScheduleLoadRequested extends ScheduleEvent {
  const ScheduleLoadRequested();
}

class ScheduleSearchChanged extends ScheduleEvent {
  final String query;
  const ScheduleSearchChanged(this.query);

  @override
  List<Object> get props => [query];
}

class ScheduleDateFilterChanged extends ScheduleEvent {
  final DateTime? date;
  const ScheduleDateFilterChanged(this.date);

  @override
  List<Object> get props => [date ?? ''];
}

class ScheduleAddRequested extends ScheduleEvent {
  final Map<String, dynamic> scheduleData;
  const ScheduleAddRequested(this.scheduleData);

  @override
  List<Object> get props => [scheduleData];
}

class ScheduleDeleteRequested extends ScheduleEvent {
  final int scheduleId;
  const ScheduleDeleteRequested(this.scheduleId);

  @override
  List<Object> get props => [scheduleId];
}

class ScheduleStateReset extends ScheduleEvent {
  const ScheduleStateReset();

  @override
  List<Object> get props => [];
}
