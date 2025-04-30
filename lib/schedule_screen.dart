import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'main.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredSchedules = [];
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterSchedules);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => isLoading = true);

      final schedulesResponse = await supabase
          .from('Schedule')
          .select('''
        *,
        User!inner(Surname, Name, Patronymic, Specialization),
        Cabinet!inner(ID_Cabinet, Name)
      ''')
          .order('Date', ascending: true);

      if (mounted) {
        setState(() {
          schedules = List<Map<String, dynamic>>.from(schedulesResponse);
          filteredSchedules = List.from(schedules);
          isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Ошибка загрузки данных: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: ${e.toString()}')),
        );
      }
    }
  }

  void _filterSchedules() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredSchedules =
          schedules.where((schedule) {
            final doctor = schedule['User'] ?? {};
            final surname = doctor['Surname'] ?? '';
            final name = doctor['Name'] ?? '';
            final patronymic = doctor['Patronymic'] ?? '';
            final specialization = doctor['Specialization'] ?? '';
            final fullName = '$surname $name $patronymic'.toLowerCase();

            final cabinet = schedule['Cabinet'] ?? {};
            final cabinetName = cabinet['Name'] ?? ''.toLowerCase();

            final startTime = schedule['Time_Start'] ?? '';
            final endTime = schedule['Time_End'] ?? '';
            final timeMatch = '$startTime-$endTime'.toLowerCase().contains(
              query,
            );

            return fullName.contains(query) ||
                specialization.toLowerCase().contains(query) ||
                cabinetName.contains(query) ||
                timeMatch;
          }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _filterByDate(picked);
      });
    }
  }

  void _filterByDate(DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    setState(() {
      filteredSchedules =
          schedules.where((schedule) {
            final scheduleDate = schedule['Date'] ?? '';
            return scheduleDate.toString().contains(dateStr);
          }).toList();
    });
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
      filteredSchedules = List.from(schedules);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    hintText: 'ФИО, специальность или кабинет',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Дата',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? _selectedDate!.toIso8601String().substring(
                                  0,
                                  10,
                                )
                                : 'Все даты',
                          ),
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearDateFilter,
                        tooltip: 'Сбросить фильтр по дате',
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredSchedules.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 64,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty &&
                                    _selectedDate == null
                                ? 'Нет записей в расписании'
                                : 'Записи не найдены',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredSchedules.length,
                      itemBuilder: (context, index) {
                        final schedule = filteredSchedules[index];
                        final doctor = schedule['User'] ?? {};
                        final cabinet = schedule['Cabinet'] ?? {};
                        final surname = doctor['Surname'] ?? '';
                        final name = doctor['Name'] ?? '';
                        final patronymic = doctor['Patronymic'] ?? '';
                        final specialization = doctor['Specialization'] ?? '';
                        final fullName = '$surname $name $patronymic';
                        final cabinetName = cabinet['Name'] ?? 'Не указан';
                        final date = schedule['Date'] ?? '--';
                        final startTime = schedule['Time_Start'] ?? '--';
                        final endTime = schedule['Time_End'] ?? '--';

                        return Card(
                          child: ListTile(
                            title: Text(fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (specialization.isNotEmpty)
                                  Text('Специальность: $specialization'),
                                Text('Кабинет: $cabinetName'),
                                Text(
                                  'Дата: ${date.toString().substring(0, 10)}',
                                ),
                                Text('Время: $startTime - $endTime'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        tooltip: 'Обновить',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
