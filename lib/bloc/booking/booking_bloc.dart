// lib/booking/bloc/booking_bloc.dart
import 'package:clinic_app/models/service_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../repositories/booking_repository.dart';

part 'booking_event.dart';
part 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository bookingRepo;
  final SupabaseClient supabase;

  BookingBloc({
    required this.bookingRepo,
    required this.supabase,
    DateTime? initialDate,
  }) : super(BookingState(date: initialDate ?? DateTime.now())) {
    on<BookingStarted>(_onStarted);
    on<BookingDateChanged>(_onDateChanged);
    on<BookingDoctorSelected>(_onDoctorSelected);
    on<BookingTimeSelected>(_onTimeSelected);
    on<BookingPaymentMethodSelected>(_onPaymentMethodSelected);
    on<BookingSubmitRequested>(_onSubmit);
  }

  String _specToRu(Specialization spec) {
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

  Future<void> _onStarted(BookingStarted e, Emitter<BookingState> emit) async {
    emit(state.copyWith(status: BookingStatus.loading, service: e.service));
    await _loadDoctorsAndSlots(emit, keepDoctor: false);
  }

  Future<void> _onDateChanged(
    BookingDateChanged e,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading, date: e.date));
    await _loadDoctorsAndSlots(emit, keepDoctor: true);
  }

  Future<void> _onDoctorSelected(
    BookingDoctorSelected e,
    Emitter<BookingState> emit,
  ) async {
    emit(
      state.copyWith(
        status: BookingStatus.loading,
        selectedDoctor: e.doctor,
        selectedTime: null,
      ),
    );
    await _loadSlotsForDoctor(emit);
  }

  void _onTimeSelected(BookingTimeSelected e, Emitter<BookingState> emit) {
    emit(state.copyWith(selectedTime: e.time));
  }

  void _onPaymentMethodSelected(
    BookingPaymentMethodSelected e,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(selectedPaymentMethod: e.paymentMethod));
  }

  Future<void> _loadDoctorsAndSlots(
    Emitter<BookingState> emit, {
    required bool keepDoctor,
  }) async {
    try {
      final service = state.service!;
      final specRu = _specToRu(service.specialization!);
      final doctorsRaw = await bookingRepo.getDoctorsWithScheduleForDate(
        specializationRu: specRu,
        date: state.date,
      );
      final doctors = doctorsRaw.map((m) => UserModel.fromJson(m)).toList();

      // FIX: безопасный выбор сохранённого врача без кастов из null
      UserModel? selected;
      if (keepDoctor && state.selectedDoctor != null) {
        final idx = doctors.indexWhere((d) => d.id == state.selectedDoctor!.id);
        if (idx != -1) {
          selected = doctors[idx];
        } else {
          selected = doctors.isNotEmpty ? doctors.first : null;
        }
      } else {
        selected = doctors.isNotEmpty ? doctors.first : null;
      }

      emit(state.copyWith(doctors: doctors, selectedDoctor: selected));
      await _loadSlotsForDoctor(emit);
    } catch (err) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          error: 'Ошибка загрузки докторов: $err',
        ),
      );
    }
  }

  Future<void> _loadSlotsForDoctor(Emitter<BookingState> emit) async {
    if (state.selectedDoctor == null) {
      emit(state.copyWith(status: BookingStatus.ready, slots: const []));
      return;
    }
    try {
      final schedules = await bookingRepo.getSchedulesForDoctorDate(
        doctorId: state.selectedDoctor!.id,
        date: state.date,
      );
      final booked = await bookingRepo.getBookedTimes(
        doctorId: state.selectedDoctor!.id,
        date: state.date,
      );

      final slots = <Slot>[];
      for (final s in schedules) {
        // 'HH:MM:SS'
        TimeOfDay parse(String t) {
          final hh = int.parse(t.substring(0, 2));
          final mm = int.parse(t.substring(3, 5));
          return TimeOfDay(hour: hh, minute: mm);
        }

        final start = parse(s['Time_Start']);
        final end = parse(s['Time_End']);
        TimeOfDay cur = start;
        int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;
        TimeOfDay add30(TimeOfDay t) {
          final m = toMinutes(t) + 30;
          return TimeOfDay(hour: m ~/ 60, minute: m % 60);
        }

        String fmt(TimeOfDay t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

        while (toMinutes(cur) < toMinutes(end)) {
          final hhmm = fmt(cur);
          final busy = booked.contains(hhmm);
          slots.add(Slot(cur, busy));
          cur = add30(cur);
        }
      }

      final map = <String, Slot>{};
      for (final sl in slots) {
        final key =
            '${sl.time.hour.toString().padLeft(2, '0')}:${sl.time.minute.toString().padLeft(2, '0')}';
        map[key] = Slot(sl.time, sl.busy);
      }
      final finalSlots = map.values.toList()
        ..sort((a, b) {
          final am = a.time.hour * 60 + a.time.minute;
          final bm = b.time.hour * 60 + b.time.minute;
          return am.compareTo(bm);
        });

      emit(
        state.copyWith(
          status: BookingStatus.ready,
          slots: finalSlots,
          selectedTime: null,
        ),
      );
    } catch (err) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          error: 'Ошибка загрузки слотов: $err',
        ),
      );
    }
  }

  Future<void> _onSubmit(
    BookingSubmitRequested e,
    Emitter<BookingState> emit,
  ) async {
    if (state.selectedDoctor == null ||
        state.selectedTime == null ||
        state.selectedPaymentMethod == null ||
        state.service == null) {
      return;
    }

    emit(state.copyWith(status: BookingStatus.submitting));

    try {
      final userId = supabase.auth.currentUser!.id;
      final doctorId = state.selectedDoctor!.id;
      final hhmm =
          '${state.selectedTime!.hour.toString().padLeft(2, '0')}:${state.selectedTime!.minute.toString().padLeft(2, '0')}';

      final vizitId = await bookingRepo.createVizit(
        patientId: userId,
        doctorId: doctorId,
        date: state.date,
        hhmm: hhmm,
      );

      final pcardId = await bookingRepo.getOrCreatePatientCard(userId);

      await bookingRepo.createIssue(
        pcardId: pcardId,
        vizitId: vizitId,
        serviceId: state.service!.id,
      );

      await bookingRepo.createPayment(
        vizitId: vizitId,
        methodRu: state.selectedPaymentMethod!.value,
      );

      emit(state.copyWith(status: BookingStatus.success));
    } catch (err) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          error: 'Не удалось создать запись: $err',
        ),
      );
    }
  }
}
