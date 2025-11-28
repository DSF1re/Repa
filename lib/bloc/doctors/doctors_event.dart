part of 'doctors_bloc.dart';

abstract class DoctorsEvent extends Equatable {
  const DoctorsEvent();

  @override
  List<Object?> get props => [];
}

class DoctorsLoadRequested extends DoctorsEvent {}

class DoctorsSearchChanged extends DoctorsEvent {
  final String query;

  const DoctorsSearchChanged(this.query);

  @override
  List<Object> get props => [query];
}

class DoctorUpdateRequested extends DoctorsEvent {
  final UserModel doctor;

  const DoctorUpdateRequested(this.doctor);

  @override
  List<Object> get props => [doctor];
}

class DoctorDeactivateRequested extends DoctorsEvent {
  final String doctorId;

  const DoctorDeactivateRequested(this.doctorId);

  @override
  List<Object> get props => [doctorId];
}

class DoctorsStateReset extends DoctorsEvent {
  const DoctorsStateReset();

  @override
  List<Object> get props => [];
}
