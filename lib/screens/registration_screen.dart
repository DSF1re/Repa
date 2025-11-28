import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../models/user_model.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _surnameController = TextEditingController();
  final _nameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passportController = TextEditingController();

  bool _obscurePassword = true;
  final _russianLettersRegex = RegExp(r'[а-яА-ЯёЁ]');

  UserRole? _selectedRole;
  Specialization? _selectedSpecialization;
  DateTime? _selectedDate;

  final _passportFormatter = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 10) return oldValue;
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 4) newText += ' ';
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  });

  @override
  void dispose() {
    _surnameController.dispose();
    _nameController.dispose();
    _patronymicController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passportController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == null ||
        _selectedDate == null ||
        _passportController.text.length < 11 ||
        (_selectedRole == UserRole.doctor && _selectedSpecialization == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }

    final userData = UserModel(
      id: '',
      surname: _surnameController.text.trim(),
      name: _nameController.text.trim(),
      patronymic: _patronymicController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      birthDate: _selectedDate!,
      passport: _passportController.text.trim(),
      role: _selectedRole!,
      specialization: _selectedSpecialization,
      status: UserStatus.unconfirmed,
    );

    context.read<AppAuthBloc>().add(
      AppAuthSignUpRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        userData: userData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocListener<AppAuthBloc, AppAuthState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          } else if (state.status == AppAuthStatus.unauthenticated &&
              !state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Письмо с подтверждением отправлено на ваш email',
                ),
              ),
            );
            Navigator.pop(context);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigoAccent, Colors.deepPurple],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Регистрация',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildPersonalDataFields(),
                          const SizedBox(height: 16),
                          _buildContactFields(),
                          const SizedBox(height: 16),
                          _buildRoleFields(),
                          const SizedBox(height: 16),
                          _buildDateField(),
                          const SizedBox(height: 16),
                          _buildPassportField(),
                          const SizedBox(height: 24),
                          _buildRegisterButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalDataFields() {
    return Column(
      children: [
        TextFormField(
          controller: _surnameController,
          decoration: InputDecoration(
            labelText: 'Фамилия*',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(_russianLettersRegex),
            LengthLimitingTextInputFormatter(50),
          ],
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Обязательное поле' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Имя*',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(_russianLettersRegex),
            LengthLimitingTextInputFormatter(50),
          ],
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Обязательное поле' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _patronymicController,
          decoration: InputDecoration(
            labelText: 'Отчество',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(_russianLettersRegex),
            LengthLimitingTextInputFormatter(50),
          ],
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  Widget _buildContactFields() {
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email*',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Обязательное поле';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Некорректный email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Пароль*',
            prefixIcon: const Icon(Icons.lock_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Обязательное поле';
            if (value!.length < 6) return 'Минимум 6 символов';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRoleFields() {
    return Column(
      children: [
        DropdownButtonFormField<UserRole>(
          initialValue: _selectedRole,
          decoration: InputDecoration(
            labelText: 'Роль*',
            prefixIcon: const Icon(Icons.work_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: UserRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(_getRoleString(role)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
              if (value != UserRole.doctor) {
                _selectedSpecialization = null;
              }
            });
          },
          validator: (value) => value == null ? 'Выберите роль' : null,
        ),
        if (_selectedRole == UserRole.doctor) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<Specialization>(
            initialValue: _selectedSpecialization,
            decoration: InputDecoration(
              labelText: 'Специализация*',
              prefixIcon: const Icon(Icons.medical_services_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: Specialization.values.map((spec) {
              return DropdownMenuItem(
                value: spec,
                child: Text(_getSpecializationString(spec)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpecialization = value;
              });
            },
            validator: (value) =>
                value == null ? 'Выберите специализацию' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Дата рождения*',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _selectedDate != null
              ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
              : 'Выберите дату',
        ),
      ),
    );
  }

  Widget _buildPassportField() {
    return TextFormField(
      controller: _passportController,
      decoration: InputDecoration(
        labelText: 'Паспорт*',
        prefixIcon: const Icon(Icons.credit_card_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'XXXX XXXXX',
      ),
      inputFormatters: [
        _passportFormatter,
        LengthLimitingTextInputFormatter(11),
      ],
      keyboardType: TextInputType.number,
      validator: (value) => value?.isEmpty ?? true ? 'Обязательное поле' : null,
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<AppAuthBloc, AppAuthState>(
        builder: (context, state) {
          return ElevatedButton(
            onPressed: state.isLoading ? null : _register,
            child: state.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Зарегистрироваться',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          );
        },
      ),
    );
  }

  String _getRoleString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.doctor:
        return 'Доктор';
      case UserRole.patient:
        return 'Пациент';
    }
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
}
