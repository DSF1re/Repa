part of 'doctors_bloc.dart';

enum DoctorsStatus { initial, loading, success, failure }

class DoctorsState extends Equatable {
  final DoctorsStatus status;
  final List<UserModel> doctors;
  final List<UserModel> filteredDoctors;
  final String searchQuery;
  final String? errorMessage;

  const DoctorsState({
    this.status = DoctorsStatus.initial,
    this.doctors = const [],
    this.filteredDoctors = const [],
    this.searchQuery = '',
    this.errorMessage,
  });

  DoctorsState copyWith({
    DoctorsStatus? status,
    List<UserModel>? doctors,
    List<UserModel>? filteredDoctors,
    String? searchQuery,
    String? errorMessage,
  }) {
    return DoctorsState(
      status: status ?? this.status,
      doctors: doctors ?? this.doctors,
      filteredDoctors: filteredDoctors ?? this.filteredDoctors,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    doctors,
    filteredDoctors,
    searchQuery,
    errorMessage,
  ];
}
