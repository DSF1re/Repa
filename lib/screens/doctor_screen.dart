import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/doctors/doctors_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../models/user_model.dart';
import 'edit_doctor_screen.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorsBloc, DoctorsState>(
      builder: (context, state) {
        if (state.status == DoctorsStatus.initial) {
          context.read<DoctorsBloc>().add(DoctorsLoadRequested());
        }
        return const DoctorsView();
      },
    );
  }
}

class DoctorsView extends StatefulWidget {
  const DoctorsView({super.key});

  @override
  State<DoctorsView> createState() => _DoctorsViewState();
}

class _DoctorsViewState extends State<DoctorsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<DoctorsBloc, DoctorsState>(
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
                  hintText: 'Введите ФИО врача',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                onChanged: (query) {
                  context.read<DoctorsBloc>().add(DoctorsSearchChanged(query));
                },
              ),
            ),
            Expanded(
              child: BlocBuilder<DoctorsBloc, DoctorsState>(
                builder: (context, state) {
                  switch (state.status) {
                    case DoctorsStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case DoctorsStatus.failure:
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
                              'Ошибка загрузки врачей',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<DoctorsBloc>().add(
                                DoctorsLoadRequested(),
                              ),
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      );
                    case DoctorsStatus.success:
                      if (state.filteredDoctors.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Нет врачей в системе'
                                    : 'Врачи не найдены',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        itemCount: state.filteredDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = state.filteredDoctors[index];
                          return DoctorListTile(doctor: doctor);
                        },
                      );
                    case DoctorsStatus.initial:
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

class DoctorListTile extends StatelessWidget {
  final UserModel doctor;

  const DoctorListTile({super.key, required this.doctor});

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
                doctor.surname.isNotEmpty
                    ? doctor.surname.substring(0, 1).toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(doctor.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doctor.specialization != null)
                  Text(
                    'Специальность: ${_getSpecializationString(doctor.specialization!)}',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                Text(
                  'Email: ${doctor.email}',
                  style: const TextStyle(fontSize: 12),
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
                  builder: (context) => EditDoctorScreen(doctor: doctor),
                ),
              ).then((result) {
                if (!context.mounted) return;
                if (result == true) {
                  context.read<DoctorsBloc>().add(DoctorsLoadRequested());
                }
              });
            },
          ),
        );
      },
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
}
