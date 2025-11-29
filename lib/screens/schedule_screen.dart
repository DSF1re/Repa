import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/schedule/schedule_bloc.dart';
import '../../../bloc/auth/auth_bloc.dart';
import '../../../models/user_model.dart';
import 'add_schedule_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state.status == ScheduleStatus.initial) {
          context.read<ScheduleBloc>().add(const ScheduleLoadRequested());
        }

        return const ScheduleView();
      },
    );
  }
}

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = context.read<ScheduleBloc>().state.selectedDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && context.mounted) {
      context.read<ScheduleBloc>().add(ScheduleDateFilterChanged(picked));
    }
  }

  void _clearDateFilter() {
    context.read<ScheduleBloc>().add(const ScheduleDateFilterChanged(null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ScheduleBloc, ScheduleState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  switch (state.status) {
                    case ScheduleStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case ScheduleStatus.failure:
                      return _buildErrorState();
                    case ScheduleStatus.success:
                      if (state.filteredSchedules.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildScheduleList(state.filteredSchedules);
                    case ScheduleStatus.initial:
                      return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<AppAuthBloc, AppAuthState>(
        builder: (context, authState) {
          final isAdmin = authState.user?.role == UserRole.admin;
          if (!isAdmin) return const SizedBox.shrink();

          return FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddScheduleScreen(),
                ),
              );

              if (result == true && context.mounted) {
                context.read<ScheduleBloc>().add(const ScheduleLoadRequested());
              }
            },
            tooltip: 'Добавить расписание',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск',
              hintText: 'ФИО, специальность или кабинет',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: (query) {
              context.read<ScheduleBloc>().add(ScheduleSearchChanged(query));
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder: (context, state) {
                    return InkWell(
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
                          state.selectedDate != null
                              ? state.selectedDate!.toIso8601String().substring(
                                  0,
                                  10,
                                )
                              : 'Актуальные',
                        ),
                      ),
                    );
                  },
                ),
              ),
              BlocBuilder<ScheduleBloc, ScheduleState>(
                builder: (context, state) {
                  if (state.selectedDate != null) {
                    return IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearDateFilter,
                      tooltip: 'Сбросить фильтр по дате',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Ошибка загрузки расписания',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                context.read<ScheduleBloc>().add(const ScheduleLoadRequested()),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                state.searchQuery.isEmpty && state.selectedDate == null
                    ? 'Нет записей в расписании'
                    : 'Записи не найдены',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleList(List<Map<String, dynamic>> schedules) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        return ScheduleListTile(schedule: schedules[index]);
      },
    );
  }
}

class ScheduleListTile extends StatelessWidget {
  final Map<String, dynamic> schedule;

  const ScheduleListTile({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
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

    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, authState) {
        final isAdmin = authState.user?.role == UserRole.admin;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Icon(
                Icons.medical_services,
                color: Colors.deepPurple.shade700,
              ),
            ),
            title: Text(fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (specialization.isNotEmpty)
                  Text(
                    'Специальность: $specialization',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                Text('Кабинет: $cabinetName'),
                Text('Дата: ${date.toString().substring(0, 10)}'),
                Text(
                  'Время: $startTime - $endTime',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            trailing: isAdmin
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _confirmDelete(context, schedule['ID_Schedule']);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить'),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text(
          'Вы уверены, что хотите удалить эту запись из расписания?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ScheduleBloc>().add(
                ScheduleDeleteRequested(scheduleId),
              );
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
