part of 'booking_bloc.dart';

class Slot {
  final TimeOfDay time;
  final bool busy;
  const Slot(this.time, this.busy);
}

enum BookingStatus { initial, loading, ready, submitting, success, failure }

enum PaymentMethod { cash, sbp }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.sbp:
        return 'СБП';
    }
  }

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.sbp:
        return 'СБП';
    }
  }
}

class BookingState extends Equatable {
  final BookingStatus status;
  final ServiceModel? service;
  final DateTime date;
  final List<UserModel> doctors;
  final UserModel? selectedDoctor;
  final List<Slot> slots;
  final TimeOfDay? selectedTime;
  final PaymentMethod? selectedPaymentMethod;
  final String? error;

  const BookingState({
    this.status = BookingStatus.initial,
    this.service,
    required this.date,
    this.doctors = const [],
    this.selectedDoctor,
    this.slots = const [],
    this.selectedTime,
    this.selectedPaymentMethod,
    this.error,
  });

  BookingState copyWith({
    BookingStatus? status,
    ServiceModel? service,
    DateTime? date,
    List<UserModel>? doctors,
    UserModel? selectedDoctor,
    List<Slot>? slots,
    TimeOfDay? selectedTime,
    PaymentMethod? selectedPaymentMethod,
    String? error,
  }) {
    return BookingState(
      status: status ?? this.status,
      service: service ?? this.service,
      date: date ?? this.date,
      doctors: doctors ?? this.doctors,
      selectedDoctor: selectedDoctor ?? this.selectedDoctor,
      slots: slots ?? this.slots,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    service,
    date,
    doctors,
    selectedDoctor,
    slots,
    selectedTime,
    selectedPaymentMethod,
    error,
  ];
}
