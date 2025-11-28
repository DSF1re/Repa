part of 'services_bloc.dart';

enum ServicesStatus { initial, loading, success, failure }

class ServicesState extends Equatable {
  final ServicesStatus status;
  final List<ServiceModel> services;
  final String? errorMessage;

  const ServicesState({
    this.status = ServicesStatus.initial,
    this.services = const [],
    this.errorMessage,
  });

  ServicesState copyWith({
    ServicesStatus? status,
    List<ServiceModel>? services,
    String? errorMessage,
  }) {
    return ServicesState(
      status: status ?? this.status,
      services: services ?? this.services,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, services, errorMessage];
}
