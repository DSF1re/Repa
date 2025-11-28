import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/schedule/schedule_bloc.dart';
import '../../repositories/schedule_repository.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scheduleRepository = ScheduleRepository();

  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _cabinets = [];

  String? _selectedDoctorId;
  int? _selectedCabinetId;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final doctors = await _scheduleRepository.getDoctors();
      final cabinets = await _scheduleRepository.getCabinets();

      if (mounted) {
        setState(() {
          _doctors = doctors;
          _cabinets = cabinets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки данных: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _saveSchedule() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите врача')));
      return;
    }

    if (_selectedCabinetId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите кабинет')));
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите дату')));
      return;
    }

    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите время начала и окончания')),
      );
      return;
    }

    // Проверяем, что время окончания позже времени начала
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Время окончания должно быть позже времени начала'),
        ),
      );
      return;
    }

    final scheduleData = {
      'ID_Doctor': _selectedDoctorId,
      'ID_Cabinet': _selectedCabinetId,
      'Date': _selectedDate!.toIso8601String().split('T')[0],
      'Time_Start':
          '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
      'Time_End':
          '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
    };

    context.read<ScheduleBloc>().add(ScheduleAddRequested(scheduleData));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleBloc, ScheduleState>(
      listenWhen: (previous, current) {
        // Слушаем только изменения статуса
        return previous.status != current.status;
      },
      listener: (context, state) {
        if (!mounted) return; // ✅ Проверка mounted

        if (state.status == ScheduleStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Произошла ошибка')),
          );
        }

        if (state.status == ScheduleStatus.success) {
          // ✅ Сбрасываем состояние блока
          context.read<ScheduleBloc>().add(const ScheduleStateReset());

          // ✅ Отложенная навигация
          Future.microtask(() {
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true);
            }
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Добавить расписание'),
          actions: [
            BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                final isSaving = state.status == ScheduleStatus.loading;
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
                  onPressed: isSaving ? null : _saveSchedule,
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDoctorDropdown(),
                      const SizedBox(height: 16),
                      _buildCabinetDropdown(),
                      const SizedBox(height: 16),
                      _buildDateSelector(),
                      const SizedBox(height: 16),
                      _buildTimeSelectors(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedDoctorId,
      decoration: const InputDecoration(
        labelText: 'Врач *',
        prefixIcon: Icon(Icons.medical_services),
        border: OutlineInputBorder(),
      ),
      items: _doctors.map((doctor) {
        return DropdownMenuItem<String>(
          value: doctor['ID_User'],
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 120,
            child: Text(
              '${doctor['Surname']} ${doctor['Name']} ${doctor['Patronymic'] ?? ''} - ${doctor['Specialization']}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedDoctorId = value);
      },
      validator: (value) {
        if (value == null) return 'Выберите врача';
        return null;
      },
    );
  }

  Widget _buildCabinetDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedCabinetId,
      decoration: const InputDecoration(
        labelText: 'Кабинет *',
        prefixIcon: Icon(Icons.room),
        border: OutlineInputBorder(),
      ),
      items: _cabinets.map((cabinet) {
        return DropdownMenuItem<int>(
          value: cabinet['ID_Cabinet'],
          child: Text(cabinet['Name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedCabinetId = value);
      },
      validator: (value) {
        if (value == null) return 'Выберите кабинет';
        return null;
      },
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Дата *',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          _selectedDate != null
              ? _selectedDate!.toIso8601String().split('T')[0]
              : 'Выберите дату',
        ),
      ),
    );
  }

  Widget _buildTimeSelectors() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(true),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Время начала *',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _startTime != null
                    ? _startTime!.format(context)
                    : 'Выберите время',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(false),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Время окончания *',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _endTime != null ? _endTime!.format(context) : 'Выберите время',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          final isSaving = state.status == ScheduleStatus.loading;
          return ElevatedButton(
            onPressed: isSaving ? null : _saveSchedule,
            child: isSaving
                ? const CircularProgressIndicator()
                : const Text('Сохранить расписание'),
          );
        },
      ),
    );
  }
}
