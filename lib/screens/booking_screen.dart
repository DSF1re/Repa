import 'package:clinic_app/repositories/booking_repository.dart';
import 'package:clinic_app/bloc/booking/booking_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/auth/auth_bloc.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';

class BookingScreen extends StatelessWidget {
  final ServiceModel service;

  const BookingScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, authState) {
        if (authState.status != AppAuthStatus.authenticated) {
          return _buildUnauthorizedScreen(
            context,
            'Войдите в систему как пациент',
          );
        }

        if (authState.user?.role != UserRole.patient) {
          return _buildUnauthorizedScreen(
            context,
            'Запись доступна только для пациентов',
          );
        }

        return BlocProvider(
          create: (context) {
            final supabase = Supabase.instance.client;
            final bookingRepo = BookingRepository(supabase);

            return BookingBloc(bookingRepo: bookingRepo, supabase: supabase)
              ..add(BookingStarted(service));
          },
          child: BookingView(service: service),
        );
      },
    );
  }

  Widget _buildUnauthorizedScreen(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Запись на прием'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Text('Вернуться назад'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingView extends StatelessWidget {
  final ServiceModel service;

  const BookingView({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Запись на прием'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state.status == BookingStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error ?? 'Произошла ошибка'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == BookingStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Запись успешно создана!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceCard(context, service),
                const SizedBox(height: 24),
                _buildDateSelection(context, state),
                const SizedBox(height: 24),
                _buildDoctorSelection(context, state),
                const SizedBox(height: 24),
                _buildTimeSlots(context, state),
                const SizedBox(height: 24),
                _buildPaymentMethodSelection(context, state), // ✅ Добавлено
                const SizedBox(height: 32),
                _buildBookButton(context, state),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceModel service) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_services,
                  color: Colors.deepPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${service.price.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (service.description != null) ...[
            const SizedBox(height: 16),
            Text(
              service.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateSelection(BuildContext context, BookingState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Выберите дату',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple.withAlpha(75)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.deepPurple.withAlpha(25),
              ),
              child: Row(
                children: [
                  Text(
                    _formatDate(state.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorSelection(BuildContext context, BookingState state) {
    if (state.status == BookingStatus.loading) {
      return _buildLoadingCard('Загрузка врачей...');
    }

    if (state.doctors.isEmpty) {
      return _buildEmptyCard('На выбранную дату врачи недоступны');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Выберите врача',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...state.doctors.map(
            (doctor) => _buildDoctorCard(context, doctor, state),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(
    BuildContext context,
    UserModel doctor,
    BookingState state,
  ) {
    final isSelected = state.selectedDoctor?.id == doctor.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.read<BookingBloc>().add(BookingDoctorSelected(doctor));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey.withAlpha(75),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? Colors.deepPurple.withAlpha(25)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple.withAlpha(25),
                child: Text(
                  '${doctor.surname[0]}${doctor.name[0]}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${doctor.surname} ${doctor.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.deepPurple : Colors.black87,
                      ),
                    ),
                    if (doctor.patronymic != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.patronymic!,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      doctor.specialization!.displayName,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: Colors.deepPurple, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlots(BuildContext context, BookingState state) {
    if (state.selectedDoctor == null) {
      return _buildEmptyCard('Сначала выберите врача');
    }

    if (state.status == BookingStatus.loading) {
      return _buildLoadingCard('Загрузка расписания...');
    }

    if (state.slots.isEmpty) {
      return _buildEmptyCard('На выбранную дату нет доступных слотов');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Выберите время',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: state.slots
                .map((slot) => _buildTimeSlot(context, slot, state))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(BuildContext context, Slot slot, BookingState state) {
    final isSelected = state.selectedTime == slot.time;
    final isBusy = slot.busy;

    return InkWell(
      onTap: isBusy
          ? null
          : () {
              context.read<BookingBloc>().add(BookingTimeSelected(slot.time));
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isBusy
              ? Colors.grey.withAlpha(25)
              : isSelected
              ? Colors.deepPurple
              : Colors.deepPurple.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBusy
                ? Colors.grey.withAlpha(75)
                : isSelected
                ? Colors.deepPurple
                : Colors.deepPurple.withAlpha(75),
          ),
        ),
        child: Text(
          '${slot.time.hour.toString().padLeft(2, '0')}:${slot.time.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isBusy
                ? Colors.grey
                : isSelected
                ? Colors.white
                : Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelection(
    BuildContext context,
    BookingState state,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: Colors.deepPurple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Способ оплаты',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PaymentMethod>(
            initialValue: state.selectedPaymentMethod,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepPurple.withAlpha(75)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepPurple.withAlpha(75)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.deepPurple,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.deepPurple.withAlpha(25),
              hintText: 'Выберите способ оплаты',
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            items: PaymentMethod.values.map((method) {
              return DropdownMenuItem<PaymentMethod>(
                value: method,
                child: Row(
                  children: [
                    Icon(
                      method == PaymentMethod.cash
                          ? Icons.money
                          : Icons.qr_code,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      method.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (PaymentMethod? value) {
              if (value != null) {
                context.read<BookingBloc>().add(
                  BookingPaymentMethodSelected(value),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(BuildContext context, BookingState state) {
    final canBook =
        state.selectedDoctor != null &&
        state.selectedTime != null &&
        state.selectedPaymentMethod != null &&
        state.status != BookingStatus.submitting;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canBook
            ? () {
                context.read<BookingBloc>().add(const BookingSubmitRequested());
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withAlpha(75),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: state.status == BookingStatus.submitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Создание записи...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Text(
                'Записаться на прием',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: context.read<BookingBloc>().state.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.deepPurple,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<BookingBloc>().add(BookingDateChanged(picked));
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
