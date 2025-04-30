import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;
  String? currentUserRole;
  String? selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
    _fetchPatients();
  }

  Future<void> _getCurrentUserRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response =
            await supabase
                .from('User')
                .select('Role')
                .eq('ID_User', user.id)
                .single();

        if (mounted) {
          setState(() {
            currentUserRole = response['Role'];
          });
        }
      }
    } catch (e) {
      developer.log('Ошибка получения роли: $e');
    }
  }

  Future<void> _fetchPatients() async {
    try {
      setState(() => isLoading = true);
      final response = await supabase
          .from('User')
          .select()
          .eq('Role', 'Пациент')
          .neq('Status', 'Не активен') // Исключаем неактивных
          .order('Surname', ascending: true);

      if (mounted) {
        setState(() {
          patients = List<Map<String, dynamic>>.from(response);
          filteredPatients = List.from(patients);
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Ошибка загрузки пациентов: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: ${e.toString()}')),
        );
      }
    }
  }

  void _filterPatients(String query) {
    setState(() {
      filteredPatients =
          patients.where((patient) {
            final surname = patient['Surname'] ?? '';
            final name = patient['Name'] ?? '';
            final patronymic = patient['Patronymic'] ?? '';
            final fullName = '$surname $name $patronymic'.toLowerCase();

            final nameMatches = fullName.contains(query.toLowerCase());
            final statusMatches =
                selectedStatus == null || patient['Status'] == selectedStatus;

            return nameMatches && statusMatches;
          }).toList();
    });
  }

  int calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Поиск',
                    hintText: 'Введите ФИО пациента',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                  onChanged: _filterPatients,
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPatients.isEmpty
                    ? const Center(
                      child: Text(
                        'Пациенты не найдены',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredPatients.length,
                      itemBuilder: (context, index) {
                        final patient = filteredPatients[index];
                        final surname = patient['Surname'] ?? '';
                        final name = patient['Name'] ?? '';
                        final patronymic = patient['Patronymic'] ?? '';
                        final bday =
                            patient['BDay'] != null
                                ? DateTime.tryParse(patient['BDay'])
                                : null;
                        final fullName = '$surname $name $patronymic';
                        final age = bday != null ? calculateAge(bday) : null;
                        final status = patient['Status'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          child: ListTile(
                            title: Text(fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (age != null) Text('Возраст: $age лет'),
                                if (status != null) Text('Статус: $status'),
                              ],
                            ),
                            trailing:
                                currentUserRole == 'Администратор'
                                    ? const Icon(Icons.chevron_right)
                                    : null,
                            onTap: () {
                              if (currentUserRole != 'Администратор') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Только администраторы могут редактировать',
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditPatientScreen(
                                        patient: patient,
                                        currentUserRole: currentUserRole!,
                                      ),
                                ),
                              ).then((updatedPatient) {
                                if (updatedPatient != null && mounted) {
                                  setState(() {
                                    final originalIndex = patients.indexWhere(
                                      (p) => p['ID_User'] == patient['ID_User'],
                                    );
                                    if (originalIndex != -1) {
                                      patients[originalIndex] = updatedPatient;
                                    }
                                    _filterPatients(_searchController.text);
                                  });
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class EditPatientScreen extends StatefulWidget {
  final Map<String, dynamic> patient;
  final String currentUserRole;

  const EditPatientScreen({
    super.key,
    required this.patient,
    required this.currentUserRole,
  });

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  late final TextEditingController _surnameController;
  late final TextEditingController _nameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _bdayController;
  late DateTime? _selectedDate;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isDeactivating = false;

  @override
  void initState() {
    super.initState();
    _surnameController = TextEditingController(text: widget.patient['Surname']);
    _nameController = TextEditingController(text: widget.patient['Name']);
    _patronymicController = TextEditingController(
      text: widget.patient['Patronymic'],
    );

    _selectedDate =
        widget.patient['BDay'] != null
            ? DateTime.tryParse(widget.patient['BDay'])
            : null;

    _bdayController = TextEditingController(
      text:
          _selectedDate != null
              ? _selectedDate!.toIso8601String().split('T').first
              : '',
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
      return 'Поле обязательно для заполнения';
    }
    if (!RegExp(r'^[а-яА-ЯёЁ\s-]+$').hasMatch(value)) {
      return 'Только русские буквы, пробелы и дефисы';
    }
    if (value.length > 50) {
      return 'Максимальная длина — 50 символов';
    }
    return null;
  }

  String? _validatePatronymic(String value, String fieldName) {
    if (value.isNotEmpty) {
      if (!RegExp(r'^[а-яА-ЯёЁ\s-]+$').hasMatch(value)) {
        return 'Только русские буквы, пробелы и дефисы';
      }
      if (value.length > 50) {
        return 'Максимальная длина — 50 символов';
      }
      return null;
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Минимум 18 лет
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _bdayController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _deactivatePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isDeactivating = true);

    try {
      await supabase
          .from('User')
          .update({'Status': 'Не активен'})
          .eq('ID_User', widget.patient['ID_User']);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Пациент деактивирован')));
      }
    } catch (e) {
      developer.log('Ошибка деактивации пациента: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDeactivating = false);
      }
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedPatient = {
        ...widget.patient,
        'Surname': _surnameController.text.trim(),
        'Name': _nameController.text.trim(),
        'Patronymic': _patronymicController.text.trim(),
        'BDay': _bdayController.text.trim(),
      };

      await supabase
          .from('User')
          .update(updatedPatient)
          .eq('ID_User', widget.patient['ID_User']);

      if (mounted) {
        Navigator.pop(context, updatedPatient);
      }
    } catch (e) {
      developer.log('Ошибка сохранения пациента: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _confirmDeactivate() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Редактирование пациента',
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          if (widget.currentUserRole == 'Администратор')
            IconButton(
              icon:
                  _isSaving
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.save),
              onPressed: _isSaving ? null : _savePatient,
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
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _validateRequiredField(value, 'Фамилия'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[а-яА-ЯёЁ\s-]+$'),
                  ),
                  LengthLimitingTextInputFormatter(50),
                ],
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _validateRequiredField(value, 'Имя'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[а-яА-ЯёЁ\s-]+$'),
                  ),
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
                validator: (value) => _validatePatronymic(value!, 'Отчество'),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[а-яА-ЯёЁ\s-]+$'),
                  ),
                  LengthLimitingTextInputFormatter(50),
                ],
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bdayController,
                decoration: InputDecoration(
                  labelText: 'Дата рождения',
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
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Контактная информация',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${widget.patient['Email'] ?? 'Не указан'}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (widget.patient['Phone'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Телефон: ${widget.patient['Phone']}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.currentUserRole == 'Администратор')
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_off, color: Colors.white),
                    label: Text(
                      _isDeactivating
                          ? 'Деактивация...'
                          : 'Деактивировать пациента',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: _isDeactivating ? null : _confirmDeactivate,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
