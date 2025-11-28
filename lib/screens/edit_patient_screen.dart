import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/patients/patients_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../models/user_model.dart';

class EditPatientScreen extends StatefulWidget {
  final UserModel patient;

  const EditPatientScreen({super.key, required this.patient});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  late final TextEditingController _surnameController;
  late final TextEditingController _nameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _bdayController;
  late DateTime? _selectedDate;
  late UserStatus _selectedStatus; // ✅ Добавляем возможность изменения статуса
  final _formKey = GlobalKey<FormState>();
  bool _isDeactivating = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _surnameController = TextEditingController(text: widget.patient.surname);
    _nameController = TextEditingController(text: widget.patient.name);
    _patronymicController = TextEditingController(
      text: widget.patient.patronymic ?? '',
    );
    _selectedDate = widget.patient.birthDate;
    _selectedStatus = widget.patient.status; // ✅ Инициализируем статус
    _bdayController = TextEditingController(
      text: widget.patient.birthDate.toIso8601String().split('T')[0],
    );
  }

  @override
  void dispose() {
    _surnameController.dispose();
    _nameController.dispose();
    _patronymicController.dispose();
    _bdayController.dispose();
    super.dispose();
  }

  String? _validateRequiredField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Поле "$fieldName" обязательно для заполнения';
    }
    if (!RegExp(r'^[а-яА-ЯёЁ\s-]+$').hasMatch(value)) {
      return 'Только русские буквы, пробелы и дефисы';
    }
    if (value.length > 50) {
      return 'Максимальная длина — 50 символов';
    }
    return null;
  }

  String? _validatePatronymic(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^[а-яА-ЯёЁ\s-]+$').hasMatch(value)) {
        return 'Только русские буквы, пробелы и дефисы';
      }
      if (value.length > 50) {
        return 'Максимальная длина — 50 символов';
      }
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime lastDate = DateTime(now.year - 18, now.month, now.day);
    final DateTime firstDate = DateTime(1900);

    DateTime initial = _selectedDate ?? lastDate;
    if (initial.isAfter(lastDate)) initial = lastDate;
    if (initial.isBefore(firstDate)) initial = firstDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _bdayController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  void _savePatient() {
    if (!_formKey.currentState!.validate()) return;

    final updatedPatient = widget.patient.copyWith(
      surname: _surnameController.text.trim(),
      name: _nameController.text.trim(),
      patronymic: _patronymicController.text.trim().isEmpty
          ? null
          : _patronymicController.text.trim(),
      birthDate: _selectedDate!,
      status: _selectedStatus, // ✅ Сохраняем обновленный статус
    );

    context.read<PatientsBloc>().add(PatientUpdateRequested(updatedPatient));
  }

  void _confirmDeactivate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Деактивировать пациента?'),
        content: const Text(
          'Пациент будет помечен как неактивный и больше не сможет войти в систему.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deactivatePatient();
            },
            child: const Text(
              'Деактивировать',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deactivatePatient() {
    setState(() => _isDeactivating = true);
    context.read<PatientsBloc>().add(
      PatientDeactivateRequested(widget.patient.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatientsBloc, PatientsState>(
      listenWhen: (previous, current) {
        return previous.status != current.status;
      },
      listener: (context, state) {
        log('PatientsBloc state: ${state.status}');
        if (!mounted) return;

        if (state.status == PatientsStatus.failure) {
          if (mounted) setState(() => _isDeactivating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Произошла ошибка')),
          );
        }

        if (state.status == PatientsStatus.success) {
          context.read<PatientsBloc>().add(const PatientsStateReset());

          if (_isDeactivating) {
            if (mounted) setState(() => _isDeactivating = false);
            Future.microtask(() {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пациент деактивирован')),
                );
              }
            });
          } else {
            Future.microtask(() {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              }
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Редактирование пациента'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            BlocBuilder<AppAuthBloc, AppAuthState>(
              builder: (context, authState) {
                final isAdmin = authState.user?.role == UserRole.admin;
                if (!isAdmin) return const SizedBox.shrink();

                return BlocBuilder<PatientsBloc, PatientsState>(
                  builder: (context, patientsState) {
                    final isSaving =
                        patientsState.status == PatientsStatus.loading;

                    return IconButton(
                      icon: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      onPressed: isSaving ? null : _savePatient,
                    );
                  },
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPersonalInfoSection(),
                const SizedBox(height: 24),
                _buildStatusSection(), // ✅ Добавляем секцию статуса
                const SizedBox(height: 24),
                _buildContactInfoSection(),
                const SizedBox(height: 24),
                _buildDeactivateButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: Colors.deepPurple.shade600),
            const SizedBox(width: 8),
            Text(
              'Личные данные',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _surnameController,
          decoration: const InputDecoration(
            labelText: 'Фамилия *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) => _validateRequiredField(value, 'Фамилия'),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^[а-яА-ЯёЁ\s-]+$')),
            LengthLimitingTextInputFormatter(50),
          ],
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Имя *',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) => _validateRequiredField(value, 'Имя'),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^[а-яА-ЯёЁ\s-]+$')),
            LengthLimitingTextInputFormatter(50),
          ],
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _patronymicController,
          decoration: const InputDecoration(
            labelText: 'Отчество',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: _validatePatronymic,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^[а-яА-ЯёЁ\s-]+$')),
            LengthLimitingTextInputFormatter(50),
          ],
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bdayController,
          decoration: InputDecoration(
            labelText: 'Дата рождения *',
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _selectDate(context),
            ),
          ),
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Укажите дату рождения';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ✅ Новая секция для управления статусом
  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_ind, color: Colors.deepPurple.shade600),
            const SizedBox(width: 8),
            Text(
              'Статус пациента',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<UserStatus>(
          initialValue: _selectedStatus,
          decoration: InputDecoration(labelText: 'Статус *'),
          items: UserStatus.values.map((UserStatus status) {
            return DropdownMenuItem<UserStatus>(
              value: status,
              child: Row(
                children: [
                  Icon(status.statusIcon, size: 20, color: status.statusColor),
                  const SizedBox(width: 8),
                  Text(status.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (UserStatus? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedStatus = newValue;
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return 'Выберите статус';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_mail, color: Colors.deepPurple),
                const SizedBox(width: 8),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 120,
                  child: Text(
                    'Контактная информация',
                    overflow: TextOverflow.fade,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email_outlined, 'Email', widget.patient.email),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.cake_outlined,
              'Возраст',
              '${widget.patient.age} лет',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.credit_card_outlined,
              'Паспорт',
              widget.patient.passport ?? 'Не указан',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }

  Widget _buildDeactivateButton() {
    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, authState) {
        final isAdmin = authState.user?.role == UserRole.admin;
        if (!isAdmin) return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _isDeactivating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_off, color: Colors.white),
            label: Text(
              _isDeactivating ? 'Деактивация...' : 'Деактивировать пациента',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: _isDeactivating ? null : _confirmDeactivate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        );
      },
    );
  }
}
