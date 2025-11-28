part of 'booking_bloc.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class BookingStarted extends BookingEvent {
  final ServiceModel service;
  const BookingStarted(this.service);

  @override
  List<Object> get props => [service];
}

class BookingDateChanged extends BookingEvent {
  final DateTime date;
  const BookingDateChanged(this.date);

  @override
  List<Object> get props => [date];
}

class BookingDoctorSelected extends BookingEvent {
  final UserModel doctor;
  const BookingDoctorSelected(this.doctor);

  @override
  List<Object> get props => [doctor];
}

class BookingTimeSelected extends BookingEvent {
  final TimeOfDay time;
  const BookingTimeSelected(this.time);

  @override
  List<Object> get props => [time];
}

class BookingPaymentMethodSelected extends BookingEvent {
  final PaymentMethod paymentMethod;
  const BookingPaymentMethodSelected(this.paymentMethod);

  @override
  List<Object> get props => [paymentMethod];
}

class BookingSubmitRequested extends BookingEvent {
  const BookingSubmitRequested();
}
