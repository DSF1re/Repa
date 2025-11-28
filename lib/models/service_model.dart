import 'package:clinic_app/models/user_model.dart';
import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final int id;
  final String name;
  final String? description;
  final double price;
  final Specialization? specialization;

  const ServiceModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.specialization,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['ID_Service'],
      name: json['Name'],
      description: json['Description'],
      price: (json['Price'] as num).toDouble(),
      specialization: json['Specialization'] != null
          ? _specializationFromString(json['Specialization'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID_Service': id,
      'Name': name,
      'Description': description,
      'Price': price,
      'Specialization': specialization != null
          ? _specializationToString(specialization!)
          : null,
    };
  }

  @override
  List<Object?> get props => [id, name, description, price, specialization];

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
}
