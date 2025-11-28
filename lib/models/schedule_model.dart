import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'user_model.dart';

class ScheduleModel extends Equatable {
  final int id;
  final int cabinetId;
  final String cabinetName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String doctorId;
  final UserModel? doctor;

  const ScheduleModel({
    required this.id,
    required this.cabinetId,
    required this.cabinetName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.doctorId,
    this.doctor,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['ID_Schedule'],
      cabinetId: json['ID_Cabinet'],
      cabinetName: json['Cabinet']?['Name'] ?? '',
      date: DateTime.parse(json['Date']),
      startTime: _parseTime(json['Time_Start']),
      endTime: _parseTime(json['Time_End']),
      doctorId: json['ID_Doctor'],
      doctor: json['User'] != null ? UserModel.fromJson(json['User']) : null,
    );
  }

  static TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  List<Object?> get props => [
    id,
    cabinetId,
    cabinetName,
    date,
    startTime,
    endTime,
    doctorId,
    doctor,
  ];
}
