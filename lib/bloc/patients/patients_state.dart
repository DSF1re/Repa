part of 'patients_bloc.dart';

enum PatientsStatus { initial, loading, success, failure }

class PatientsState extends Equatable {
  final PatientsStatus status;
  final List<UserModel> patients;
  final List<UserModel> filteredPatients;
  final String searchQuery;
  final String? errorMessage;

  const PatientsState({
    this.status = PatientsStatus.initial,
    this.patients = const [],
    this.filteredPatients = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  PatientsState copyWith({
    PatientsStatus? status,
    List<UserModel>? patients,
    List<UserModel>? filteredPatients,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PatientsState(
      status: status ?? this.status,
      patients: patients ?? this.patients,
      filteredPatients: filteredPatients ?? this.filteredPatients,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    patients,
    filteredPatients,
    searchQuery,
    errorMessage,
  ];
}
