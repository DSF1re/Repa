import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  bool isLoading = true;
  String? currentUserRole;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentUserRole();
    _fetchDoctors();
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

  Future<void> _fetchDoctors() async {
    try {
      setState(() => isLoading = true);
      final response = await supabase
          .from('User')
          .select()
          .eq('Role', 'Доктор')
          .order('Surname', ascending: true);

      if (mounted) {
        setState(() {
          doctors = List<Map<String, dynamic>>.from(response);
          filteredDoctors = List.from(doctors);
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Ошибка загрузки врачей: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: ${e.toString()}')),
        );
      }
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      filteredDoctors =
          doctors.where((doctor) {
            final surname = doctor['Surname'] ?? '';
            final name = doctor['Name'] ?? '';
            final patronymic = doctor['Patronymic'] ?? '';
            final fullName = '$surname $name $patronymic'.toLowerCase();
            return fullName.contains(query.toLowerCase());
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск',
                hintText: 'Введите ФИО врача',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: _filterDoctors,
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredDoctors.isEmpty
                    ? const Center(
                      child: Text(
                        'Врачи не найдены',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredDoctors.length,
                      itemBuilder: (context, index) {
                        final doctor = filteredDoctors[index];
                        final surname = doctor['Surname'] ?? '';
                        final name = doctor['Name'] ?? '';
                        final patronymic = doctor['Patronymic'] ?? '';
                        final bday =
                            doctor['BDay'] != null
                                ? DateTime.tryParse(doctor['BDay'])
                                : null;
                        final fullName = '$surname $name $patronymic';
                        final age = bday != null ? calculateAge(bday) : null;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          elevation: 2,
                          child: ListTile(
                            title: Text(fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (age != null) Text('Возраст: $age лет'),
                                if (doctor['Email'] != null)
                                  Text(
                                    'Email: ${doctor['Email']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
                                      (context) => EditDoctorScreen(
                                        doctor: doctor,
                                        currentUserRole: currentUserRole!,
                                      ),
                                ),
                              ).then((updatedDoctor) {
                                if (updatedDoctor != null && mounted) {
                                  setState(() {
                                    final originalIndex = doctors.indexWhere(
                                      (d) => d['ID_User'] == doctor['ID_User'],
                                    );
                                    if (originalIndex != -1) {
                                      doctors[originalIndex] = updatedDoctor;
                                    }
                                    _filterDoctors(_searchController.text);
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

class EditDoctorScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final String currentUserRole;

  const EditDoctorScreen({
    super.key,
    required this.doctor,
    required this.currentUserRole,
  });

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  late final TextEditingController _surnameController;
  late final TextEditingController _nameController;
  late final TextEditingController _patronymicController;
  late final TextEditingController _bdayController;
  late DateTime? _selectedDate;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isDeleting = false;
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _surnameController = TextEditingController(text: widget.doctor['Surname']);
    _nameController = TextEditingController(text: widget.doctor['Name']);
    _patronymicController = TextEditingController(
      text: widget.doctor['Patronymic'],
    );
    _bdayController = TextEditingController(text: widget.doctor['BDay']);
    _selectedDate =
        widget.doctor['BDay'] != null
            ? DateTime.tryParse(widget.doctor['BDay'])
            : null;
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
      return 'Только русские буквы и дефис';
    }
    if (value.length > 50) {
      return 'Максимальная длина — 50 символов';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _bdayController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _removeDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isDeleting = true);

    try {
      await supabase
          .from('User')
          .delete()
          .eq('ID_User', widget.doctor['ID_User']);

      await supabase.auth.admin.deleteUser(widget.doctor['ID_User']);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('Ошибка удаления врача: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedDoctor = {
        ...widget.doctor,
        'Surname': _surnameController.text.trim(),
        'Name': _nameController.text.trim(),
        'Patronymic': _patronymicController.text.trim(),
        'BDay': _bdayController.text.trim(),
      };

      await supabase
          .from('User')
          .update(updatedDoctor)
          .eq('ID_User', widget.doctor['ID_User']);

      if (mounted) {
        Navigator.pop(context, updatedDoctor);
      }
    } catch (e) {
      developer.log('Ошибка сохранения врача: $e');
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удалить врача?'),
            content: const Text(
              'Вы уверены, что хотите удалить этого врача? Это действие нельзя отменить.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeDoctor();
                },
                child: const Text(
                  'Удалить',
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
        title: const Text('Редактирование врача'),
        actions: [
          if (widget.currentUserRole == 'Администратор')
            IconButton(
              icon:
                  _isSaving
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveDoctor,
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
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _patronymicController,
                decoration: const InputDecoration(
                  labelText: 'Отчество',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _validateRequiredField(value, 'Отчество'),
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
                        'Email: ${widget.doctor['Email'] ?? 'Не указан'}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (widget.doctor['Phone'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Телефон: ${widget.doctor['Phone']}',
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
                  child: TextButton(
                    onPressed: _isDeleting ? null : _confirmDelete,
                    child: Text(
                      _isDeleting ? 'Удаление...' : 'Удалить врача',
                      style: const TextStyle(color: Colors.red),
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
