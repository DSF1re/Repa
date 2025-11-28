part of 'patients_bloc.dart';

abstract class PatientsEvent extends Equatable {
  const PatientsEvent();

  @override
  List<Object?> get props => [];
}

class PatientsLoadRequested extends PatientsEvent {}

class PatientsSearchChanged extends PatientsEvent {
  final String query;

  const PatientsSearchChanged(this.query);

  @override
  List<Object> get props => [query];
}

class PatientUpdateRequested extends PatientsEvent {
  final UserModel patient;

  const PatientUpdateRequested(this.patient);

  @override
  List<Object> get props => [patient];
}

class PatientDeactivateRequested extends PatientsEvent {
  final String patientId;

  const PatientDeactivateRequested(this.patientId);

  @override
  List<Object> get props => [patientId];
}

class PatientsStateReset extends PatientsEvent {
  const PatientsStateReset();

  @override
  List<Object> get props => [];
}
