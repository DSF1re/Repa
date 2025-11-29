part of 'records_bloc.dart';

abstract class RecordsEvent extends Equatable {
  const RecordsEvent();

  @override
  List<Object> get props => [];
}

class RecordsLoadRequested extends RecordsEvent {
  final String userId;
  final UserRole userRole;

  const RecordsLoadRequested({required this.userId, required this.userRole});

  @override
  List<Object> get props => [userId, userRole];
}

class RecordsCreatePatientCard extends RecordsEvent {
  final String patientId;
  final String doctorId;
  final String diagnosis;
  final String recommendation;

  const RecordsCreatePatientCard({
    required this.patientId,
    required this.doctorId,
    required this.diagnosis,
    required this.recommendation,
  });

  @override
  List<Object> get props => [patientId, doctorId, diagnosis, recommendation];
}
