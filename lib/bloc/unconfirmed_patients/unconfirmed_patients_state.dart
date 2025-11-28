part of 'unconfirmed_patients_bloc.dart';

enum UnconfirmedPatientsStatus { initial, loading, success, failure }

class UnconfirmedPatientsState extends Equatable {
  final UnconfirmedPatientsStatus status;
  final List<Map<String, dynamic>> patients;
  final String? errorMessage;

  const UnconfirmedPatientsState({
    this.status = UnconfirmedPatientsStatus.initial,
    this.patients = const [],
    this.errorMessage,
  });

  UnconfirmedPatientsState copyWith({
    UnconfirmedPatientsStatus? status,
    List<Map<String, dynamic>>? patients,
    String? errorMessage,
  }) {
    return UnconfirmedPatientsState(
      status: status ?? this.status,
      patients: patients ?? this.patients,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, patients, errorMessage];
}
