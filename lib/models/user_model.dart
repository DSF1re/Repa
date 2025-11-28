import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum UserRole { admin, doctor, patient }

enum UserStatus {
  unconfirmed, // Не подтвержден
  active, // Активен
  treatment, // Назначено лечение
  healthy, // Здоров
  canceled, // Отменен
  inactive, // Не активен
}

enum Specialization {
  therapist,
  pediatrician,
  ophthalmologist,
  neurologist,
  dentist,
  traumatologist,
}

class UserModel extends Equatable {
  final String id;
  final String surname;
  final String name;
  final String? patronymic;
  final String email;
  final String password;
  final DateTime birthDate;
  final String? passport;
  final UserRole role;
  final Specialization? specialization;
  final UserStatus status;

  const UserModel({
    required this.id,
    required this.surname,
    required this.name,
    this.patronymic,
    required this.email,
    required this.password,
    required this.birthDate,
    this.passport,
    required this.role,
    this.specialization,
    required this.status,
  });

  String get fullName => '$surname $name ${patronymic ?? ''}'.trim();

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['ID_User'] as String? ?? '',
      surname: json['Surname'] as String? ?? '',
      name: json['Name'] as String? ?? '',
      patronymic: json['Patronymic'] as String?,
      email: json['Email'] as String? ?? '',
      password: json['Password'] as String? ?? '',
      birthDate: json['BDay'] != null
          ? DateTime.parse(json['BDay'])
          : DateTime.now(),
      passport: json['Passport'] as String?,
      role: _roleFromString(json['Role'] as String? ?? 'Пациент'),
      specialization: json['Specialization'] != null
          ? _specializationFromString(json['Specialization'] as String)
          : null,
      status: _statusFromString(json['Status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_User': id,
      'Surname': surname,
      'Name': name,
      'Patronymic': patronymic,
      'Email': email,
      'Password': password,
      'BDay': birthDate.toIso8601String(),
      'Passport': passport,
      'Role': _roleToString(role),
      'Specialization': specialization != null
          ? _specializationToString(specialization!)
          : null,
      'Status': _statusToString(status),
    };
  }

  UserModel copyWith({
    String? surname,
    String? name,
    String? patronymic,
    String? email,
    String? password,
    DateTime? birthDate,
    String? passport,
    UserRole? role,
    Specialization? specialization,
    UserStatus? status,
    String? phone,
  }) {
    return UserModel(
      id: id,
      surname: surname ?? this.surname,
      name: name ?? this.name,
      patronymic: patronymic ?? this.patronymic,
      email: email ?? this.email,
      password: password ?? this.password,
      birthDate: birthDate ?? this.birthDate,
      passport: passport ?? this.passport,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    surname,
    name,
    patronymic,
    email,
    password,
    birthDate,
    passport,
    role,
    specialization,
    status,
  ];

  static UserRole _roleFromString(String role) {
    switch (role) {
      case 'Администратор':
        return UserRole.admin;
      case 'Доктор':
        return UserRole.doctor;
      case 'Пациент':
        return UserRole.patient;
      default:
        return UserRole.patient;
    }
  }

  static String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.doctor:
        return 'Доктор';
      case UserRole.patient:
        return 'Пациент';
    }
  }

  static Specialization _specializationFromString(String spec) {
    switch (spec) {
      case 'Терапевт':
        return Specialization.therapist;
      case 'Педиатр':
        return Specialization.pediatrician;
      case 'Офтальмолог':
        return Specialization.ophthalmologist;
      case 'Невролог':
        return Specialization.neurologist;
      case 'Стоматолог':
        return Specialization.dentist;
      case 'Травматолог':
        return Specialization.traumatologist;
      default:
        return Specialization.therapist;
    }
  }

  static String _specializationToString(Specialization spec) {
    switch (spec) {
      case Specialization.therapist:
        return 'Терапевт';
      case Specialization.pediatrician:
        return 'Педиатр';
      case Specialization.ophthalmologist:
        return 'Офтальмолог';
      case Specialization.neurologist:
        return 'Невролог';
      case Specialization.dentist:
        return 'Стоматолог';
      case Specialization.traumatologist:
        return 'Травматолог';
    }
  }

  // ✅ Обновленный парсер статусов с поддержкой всех статусов из БД
  static UserStatus _statusFromString(String? status) {
    if (status == null) return UserStatus.unconfirmed;

    switch (status) {
      case 'Не подтвержден':
        return UserStatus.unconfirmed;
      case 'Активен':
        return UserStatus.active;
      case 'Назначено лечение':
        return UserStatus.treatment;
      case 'Здоров':
        return UserStatus.healthy;
      case 'Отменен':
        return UserStatus.canceled;
      case 'Не активен':
        return UserStatus.inactive;
      default:
        // ✅ Возвращаем дефолтное значение для неизвестных статусов
        return UserStatus.unconfirmed;
    }
  }

  // ✅ Обновленный конвертер статусов в строку
  static String _statusToString(UserStatus status) {
    switch (status) {
      case UserStatus.unconfirmed:
        return 'Не подтвержден';
      case UserStatus.active:
        return 'Активен';
      case UserStatus.treatment:
        return 'Назначено лечение';
      case UserStatus.healthy:
        return 'Здоров';
      case UserStatus.canceled:
        return 'Отменен';
      case UserStatus.inactive:
        return 'Не активен';
    }
  }
}

// ✅ Extension для удобного отображения статусов в UI
extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.unconfirmed:
        return 'Не подтвержден';
      case UserStatus.active:
        return 'Активен';
      case UserStatus.treatment:
        return 'Назначено лечение';
      case UserStatus.healthy:
        return 'Здоров';
      case UserStatus.canceled:
        return 'Отменен';
      case UserStatus.inactive:
        return 'Не активен';
    }
  }

  // ✅ Цвета для разных статусов
  Color get statusColor {
    switch (this) {
      case UserStatus.unconfirmed:
        return Colors.orange;
      case UserStatus.active:
        return Colors.green;
      case UserStatus.treatment:
        return Colors.blue;
      case UserStatus.healthy:
        return Colors.teal;
      case UserStatus.canceled:
        return Colors.red;
      case UserStatus.inactive:
        return Colors.grey;
    }
  }

  // ✅ Иконки для статусов
  IconData get statusIcon {
    switch (this) {
      case UserStatus.unconfirmed:
        return Icons.pending;
      case UserStatus.active:
        return Icons.check_circle;
      case UserStatus.treatment:
        return Icons.medical_services;
      case UserStatus.healthy:
        return Icons.favorite;
      case UserStatus.canceled:
        return Icons.cancel;
      case UserStatus.inactive:
        return Icons.block;
    }
  }
}

extension SpecializationExtension on Specialization {
  String get displayName {
    switch (this) {
      case Specialization.therapist:
        return 'Терапевт';
      case Specialization.pediatrician:
        return 'Педиатр';
      case Specialization.ophthalmologist:
        return 'Офтальмолог';
      case Specialization.neurologist:
        return 'Невролог';
      case Specialization.dentist:
        return 'Стоматолог';
      case Specialization.traumatologist:
        return 'Травматолог';
    }
  }
}
