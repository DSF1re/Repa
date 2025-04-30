import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'main.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _surnameController = TextEditingController();
  final _nameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passportController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _russianLettersRegex = RegExp(r'[а-яА-ЯёЁ]');

  final List<String> _roles = ['Администратор', 'Доктор', 'Пациент'];
  String? _selectedRole;

  final List<String> _specializations = [
    'Терапевт',
    'Педиатр',
    'Офтальмолог',
    'Невролог',
    'Стоматолог',
    'Травматолог',
  ];
  String? _selectedSpecialization;

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      locale: const Locale('ru', 'RU'),
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

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Некорректный email')));
      return;
    }

    if (_surnameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _selectedRole == null ||
        _selectedDate == null ||
        _passportController.text.length < 11 ||
        _passportController.text.isEmpty ||
        (_selectedRole == 'Доктор' && _selectedSpecialization == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userData = {
          'ID_User': response.user!.id,
          'Surname': _surnameController.text.trim(),
          'Name': _nameController.text.trim(),
          'Patronymic': _patronymicController.text.trim(),
          'Email': email,
          'Password': _passportController.text.trim(),
          'Role': _selectedRole,
          'BDay': _selectedDate!.toIso8601String(),
          'Passport': _passportController.text.trim(),
          'Status': 'Не подтвержден',
        };

        if (_selectedRole == 'Доктор') {
          userData['Specialization'] = _selectedSpecialization;
        }

        await supabase.from('User').insert(userData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Письмо с подтверждением отправлено на ваш email'),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      String errorMessage;

      if (e.message.contains('User already registered') ||
          e.message.contains('User already exists')) {
        errorMessage = 'Пользователь с таким email уже существует.';
      } else if (e.message.contains('Invalid email') ||
          e.message.contains('is invalid')) {
        errorMessage = 'Некорректный формат email.';
      } else if (e.message.contains('Email rate limit exceeded') ||
          e.message.contains('over_email_send_rate_limit')) {
        errorMessage = 'Слишком много запросов. Попробуйте позже.';
      } else if (e.message.contains('Password should be at least 6')) {
        errorMessage = 'Пароль должен быть не менее 6 символов';
      } else {
        errorMessage = 'Ошибка регистрации: ${e.message}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (e is PostgrestException && e.message.contains('insert or update')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: Электронная почта уже занята')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла ошибка: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigoAccent, Colors.deepPurple],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
              ),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
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

                      // Личные данные
                      TextFormField(
                        controller: _surnameController,
                        decoration: InputDecoration(
                          labelText: 'Фамилия*',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            _russianLettersRegex,
                          ),
                          LengthLimitingTextInputFormatter(50),
                        ],
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Обязательное поле'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Имя*',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            _russianLettersRegex,
                          ),
                          LengthLimitingTextInputFormatter(50),
                        ],
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Обязательное поле'
                                    : null,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _patronymicController,
                        decoration: InputDecoration(
                          labelText: 'Отчество',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            _russianLettersRegex,
                          ),
                          LengthLimitingTextInputFormatter(50),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Контактные данные
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email*',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Обязательное поле';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value!)) {
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Обязательное поле';
                          }
                          if (value!.length < 6) return 'Минимум 6 символов';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Роль и специализация
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Роль*',
                          prefixIcon: const Icon(Icons.work_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items:
                            _roles.map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                            if (value != 'Доктор') {
                              _selectedSpecialization = null;
                            }
                          });
                        },
                        validator:
                            (value) => value == null ? 'Выберите роль' : null,
                      ),
                      const SizedBox(height: 16),

                      if (_selectedRole == 'Доктор')
                        DropdownButtonFormField<String>(
                          value: _selectedSpecialization,
                          decoration: InputDecoration(
                            labelText: 'Специализация*',
                            prefixIcon: const Icon(
                              Icons.medical_services_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items:
                              _specializations.map((String spec) {
                                return DropdownMenuItem<String>(
                                  value: spec,
                                  child: Text(spec),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSpecialization = value;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null
                                      ? 'Выберите специализацию'
                                      : null,
                        ),
                      if (_selectedRole == 'Доктор') const SizedBox(height: 16),

                      // Дата рождения
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Дата рождения*',
                            prefixIcon: const Icon(
                              Icons.calendar_today_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                                : 'Выберите дату',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Паспортные данные
                      TextFormField(
                        controller: _passportController,
                        decoration: InputDecoration(
                          labelText: 'Паспорт*',
                          prefixIcon: const Icon(Icons.credit_card_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'XXXX XXXXX',
                        ),
                        inputFormatters: [
                          _passportFormatter,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Обязательное поле'
                                    : null,
                      ),
                      const SizedBox(height: 24),

                      // Кнопка регистрации
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child:
                              _isLoading
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
}
