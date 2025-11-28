import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/doctors/doctors_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../models/user_model.dart';

class EditDoctorScreen extends StatefulWidget {
  final UserModel doctor;

  const EditDoctorScreen({super.key, required this.doctor});

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  late final TextEditingController _surnameController;
  late final TextEditingController _nameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _bdayController;
  late DateTime? _selectedDate;
  Specialization? _selectedSpecialization;
  final _formKey = GlobalKey<FormState>();
  bool _isDeactivating = false;

  final List<Specialization> _specializations = [
    Specialization.therapist,
    Specialization.pediatrician,
    Specialization.ophthalmologist,
    Specialization.neurologist,
    Specialization.dentist,
    Specialization.traumatologist,
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _surnameController = TextEditingController(text: widget.doctor.surname);
    _nameController = TextEditingController(text: widget.doctor.name);
    _patronymicController = TextEditingController(
      text: widget.doctor.patronymic ?? '',
    );
    _selectedDate = widget.doctor.birthDate;
    _bdayController = TextEditingController(
      text: widget.doctor.birthDate.toIso8601String().split('T')[0],
    );
    _selectedSpecialization = widget.doctor.specialization;
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

  void _saveDoctor() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSpecialization == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите специализацию')));
      return;
    }

    final updatedDoctor = widget.doctor.copyWith(
      surname: _surnameController.text.trim(),
      name: _nameController.text.trim(),
      patronymic: _patronymicController.text.trim().isEmpty
          ? null
          : _patronymicController.text.trim(),
      birthDate: _selectedDate!,
      specialization: _selectedSpecialization,
    );

    context.read<DoctorsBloc>().add(DoctorUpdateRequested(updatedDoctor));
  }

  void _confirmDeactivate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Деактивировать врача?'),
        content: const Text(
          'Доктор будет помечен как неактивный и больше не сможет войти в систему.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deactivateDoctor();
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

  void _deactivateDoctor() {
    setState(() => _isDeactivating = true);
    context.read<DoctorsBloc>().add(
      DoctorDeactivateRequested(widget.doctor.id),
    );
  }

  String _getSpecializationString(Specialization specialization) {
    switch (specialization) {
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoctorsBloc, DoctorsState>(
      listenWhen: (previous, current) {
        return previous.status != current.status;
      },
      listener: (context, state) {
        log('DoctorsBloc state: ${state.status}'); // ✅ Исправлен лог
        if (!mounted) return;

        if (state.status == DoctorsStatus.failure) {
          if (mounted) setState(() => _isDeactivating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Произошла ошибка')),
          );
        }

        if (state.status == DoctorsStatus.success) {
          // ✅ Добавлен сброс состояния как у пациентов
          context.read<DoctorsBloc>().add(const DoctorsStateReset());

          if (_isDeactivating) {
            if (mounted) setState(() => _isDeactivating = false);
            Future.microtask(() {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Доктор деактивирован')),
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
          title: const Text('Редактирование врача'),
          actions: [
            BlocBuilder<AppAuthBloc, AppAuthState>(
              builder: (context, authState) {
                final isAdmin = authState.user?.role == UserRole.admin;
                if (!isAdmin) return const SizedBox.shrink();

                return BlocBuilder<DoctorsBloc, DoctorsState>(
                  builder: (context, doctorsState) {
                    final isSaving =
                        doctorsState.status == DoctorsStatus.loading;

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
                      onPressed: isSaving ? null : _saveDoctor,
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
        const SizedBox(height: 16),
        DropdownButtonFormField<Specialization>(
          initialValue: _selectedSpecialization,
          decoration: const InputDecoration(
            labelText: 'Специализация *',
            prefixIcon: Icon(Icons.medical_services_outlined),
          ),
          items: _specializations.map((Specialization specialization) {
            return DropdownMenuItem(
              value: specialization,
              child: Text(_getSpecializationString(specialization)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSpecialization = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Выберите специализацию';
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
            _buildInfoRow(Icons.email_outlined, 'Email', widget.doctor.email),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.cake_outlined,
              'Возраст',
              '${widget.doctor.age} лет',
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
              _isDeactivating ? 'Деактивация...' : 'Деактивировать врача',
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
