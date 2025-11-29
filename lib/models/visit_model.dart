import 'package:equatable/equatable.dart';

import 'user_model.dart';

class VisitModel extends Equatable {
  final int id;
  final String userId;
  final String doctorId;
  final DateTime date;
  final DateTime time;
  final UserModel? patient;
  final UserModel? doctor;
  final bool hasTreatment;

  const VisitModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.date,
    required this.time,
    this.patient,
    this.doctor,
    this.hasTreatment = false,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['ID_Vizit'] as int? ?? 0,
      userId: json['ID_User'] as String? ?? '',
      doctorId: json['ID_Doctor'] as String? ?? '',
      date: json['Date_Vizit'] != null
          ? DateTime.parse(json['Date_Vizit'])
          : DateTime.now(),
      time: json['Time_Vizit'] != null
          ? DateTime.parse('1970-01-01 ${json['Time_Vizit']}')
          : DateTime.now(),
    );
  }

  VisitModel copyWith({bool? hasTreatment}) {
    return VisitModel(
      id: id,
      userId: userId,
      doctorId: doctorId,
      date: date,
      time: time,
      patient: patient,
      doctor: doctor,
      hasTreatment: hasTreatment ?? this.hasTreatment,
    );
  }

  @override
  List<Object?> get props => [id, userId, doctorId, date, time, hasTreatment];
}

class PatientCardModel extends Equatable {
  final int id;
  final String patientId;
  final String diagnosis;
  final String recommendation;

  const PatientCardModel({
    required this.id,
    required this.patientId,
    required this.diagnosis,
    required this.recommendation,
  });

  factory PatientCardModel.fromJson(Map<String, dynamic> json) {
    return PatientCardModel(
      id: json['ID_PCard'] as int? ?? 0,
      patientId: json['ID_Patient'] as String? ?? '',
      diagnosis: json['Diagnosis'] as String? ?? '',
      recommendation: json['Recomendation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_PCard': id,
      'ID_Patient': patientId,
      'Diagnosis': diagnosis,
      'Recomendation': recommendation,
    };
  }

  @override
  List<Object?> get props => [id, patientId, diagnosis, recommendation];
}
