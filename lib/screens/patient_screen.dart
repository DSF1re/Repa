import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/patients/patients_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../models/user_model.dart';
import 'edit_patient_screen.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientsBloc, PatientsState>(
      builder: (context, state) {
        if (state.status == PatientsStatus.initial) {
          context.read<PatientsBloc>().add(PatientsLoadRequested());
        }
        return const PatientsView();
      },
    );
  }
}

class PatientsView extends StatefulWidget {
  const PatientsView({super.key});

  @override
  State<PatientsView> createState() => _PatientsViewState();
}

class _PatientsViewState extends State<PatientsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<PatientsBloc, PatientsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
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
                onChanged: (query) {
                  context.read<PatientsBloc>().add(
                    PatientsSearchChanged(query),
                  );
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<PatientsBloc, PatientsState>(
                builder: (context, state) {
                  switch (state.status) {
                    case PatientsStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case PatientsStatus.failure:
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ошибка загрузки пациентов',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<PatientsBloc>().add(
                                PatientsLoadRequested(),
                              ),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      );
                    case PatientsStatus.success:
                      if (state.filteredPatients.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Нет пациентов в системе'
                                    : 'Пациенты не найдены',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: state.filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = state.filteredPatients[index];
                          return PatientListTile(patient: patient);
                        },
                      );
                    case PatientsStatus.initial:
                      return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientListTile extends StatelessWidget {
  final UserModel patient;

  const PatientListTile({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, authState) {
        final currentUserRole = authState.user?.role;
        final canEdit = currentUserRole == UserRole.admin;

        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              child: Text(
                patient.surname.isNotEmpty
                    ? patient.surname.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(patient.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Возраст: ${patient.age} лет'),
                Text(
                  'Email: ${patient.email}',
                  style: const TextStyle(fontSize: 12),
                ),
                // ✅ Улучшенное отображение статуса с цветами и иконками
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: patient.status.statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: patient.status.statusColor,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        patient.status.statusIcon,
                        size: 12,
                        color: patient.status.statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        patient.status.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          color: patient.status.statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: canEdit ? const Icon(Icons.chevron_right) : null,
            onTap: () {
              if (!canEdit) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Только администраторы могут редактировать'),
                  ),
                );
                return;
              }

              Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPatientScreen(patient: patient),
                ),
              ).then((result) {
                if (!context.mounted) return;
                if (result == true) {
                  context.read<PatientsBloc>().add(PatientsLoadRequested());
                }
              });
            },
          ),
        );
      },
    );
  }
}
