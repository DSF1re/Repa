part of 'unconfirmed_patients_bloc.dart';

abstract class UnconfirmedPatientsEvent extends Equatable {
  const UnconfirmedPatientsEvent();

  @override
  List<Object> get props => [];
}

class UnconfirmedPatientsLoadRequested extends UnconfirmedPatientsEvent {
  const UnconfirmedPatientsLoadRequested();
}

class PatientConfirmRequested extends UnconfirmedPatientsEvent {
  final String patientId;
  const PatientConfirmRequested(this.patientId);

  @override
  List<Object> get props => [patientId];
}

class PatientRejectRequested extends UnconfirmedPatientsEvent {
  final String patientId;
  const PatientRejectRequested(this.patientId);

  @override
  List<Object> get props => [patientId];
}

class UnconfirmedPatientsStateReset extends UnconfirmedPatientsEvent {
  const UnconfirmedPatientsStateReset();
}
