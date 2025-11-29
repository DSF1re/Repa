part of 'records_bloc.dart';

enum RecordsStatus { initial, loading, success, failure }

class RecordsState extends Equatable {
  final RecordsStatus status;
  final List<VisitModel> visits;
  final String errorMessage;

  const RecordsState({
    this.status = RecordsStatus.initial,
    this.visits = const [],
    this.errorMessage = '',
  });

  RecordsState copyWith({
    RecordsStatus? status,
    List<VisitModel>? visits,
    String? errorMessage,
  }) {
    return RecordsState(
      status: status ?? this.status,
      visits: visits ?? this.visits,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object> get props => [status, visits, errorMessage];
}
