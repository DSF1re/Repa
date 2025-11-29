import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/records/records_bloc.dart';
import '../repositories/records_repository.dart';
import '../models/visit_model.dart';
import '../models/user_model.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, authState) {
        if (authState.status != AppAuthStatus.authenticated ||
            authState.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authState.user!;

        return BlocBuilder<RecordsBloc, RecordsState>(
          builder: (context, state) {
            if (state.status == RecordsStatus.initial) {
              context.read<RecordsBloc>().add(
                RecordsLoadRequested(userId: user.id, userRole: user.role),
              );
            }

            return RecordsView(user: user, state: state);
          },
        );
      },
    );
  }
}

class RecordsView extends StatelessWidget {
  final UserModel user;
  final RecordsState state;

  const RecordsView({super.key, required this.user, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state.status) {
      case RecordsStatus.loading:
      case RecordsStatus.initial:
        return const Center(child: CircularProgressIndicator());
      case RecordsStatus.failure:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки записей',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(state.errorMessage),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.read<RecordsBloc>().add(
                  RecordsLoadRequested(userId: user.id, userRole: user.role),
                ),
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      case RecordsStatus.success:
        return _buildRecordsList(context, state.visits);
    }
  }

  Widget _buildRecordsList(BuildContext context, List<VisitModel> visits) {
    if (visits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Записей нет',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        return _buildRecordCard(context, visit);
      },
    );
  }

  Widget _buildRecordCard(BuildContext context, VisitModel visit) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.deepPurple.shade50.withValues(alpha: 0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с датой и временем
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(visit.date),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTime(visit.time),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Информация о пациенте/докторе
              if (user.role == UserRole.doctor)
                FutureBuilder<String?>(
                  future: _getPatientName(context, visit.userId),
                  builder: (context, snapshot) {
                    return _buildInfoRow(
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      label: 'Пациент',
                      value: snapshot.data ?? 'Загрузка...',
                    );
                  },
                ),
              if (user.role == UserRole.patient)
                FutureBuilder<String?>(
                  future: _getDoctorName(context, visit.doctorId),
                  builder: (context, snapshot) {
                    return _buildInfoRow(
                      icon: Icons.medical_services,
                      iconColor: Colors.green,
                      label: 'Доктор',
                      value: snapshot.data ?? 'Загрузка...',
                    );
                  },
                ),
              const SizedBox(height: 12),
              // Кнопка "Документ об оказанных услугах" для пациента
              if (user.role == UserRole.patient) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Отправить документ на почту'),
                    onPressed: visit.hasTreatment
                        ? () => _sendVisitReport(context, visit)
                        : null,
                  ),
                ),
              ],

              // Услуга
              FutureBuilder<String?>(
                future: _getServiceName(context, visit),
                builder: (context, snapshot) {
                  return _buildInfoRow(
                    icon: Icons.local_hospital,
                    iconColor: Colors.orange,
                    label: 'Услуга',
                    value: snapshot.data ?? 'Загрузка...',
                  );
                },
              ),

              // Кнопки для доктора
              if (user.role == UserRole.doctor) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      visit.hasTreatment
                          ? Icons.edit
                          : Icons.medical_information,
                      size: 20,
                    ),
                    label: Text(
                      visit.hasTreatment
                          ? 'Изменить лечение'
                          : 'Назначить лечение',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: visit.hasTreatment
                          ? Colors.amber
                          : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _showTreatmentDialog(context, visit),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendVisitReport(BuildContext context, VisitModel visit) async {
    try {
      final recordsRepo = RepositoryProvider.of<RecordsRepository>(context);

      debugPrint('SEND_VISIT_REPORT for visit ${visit.id}');
      final toEmail = user.email;

      final doctorName =
          await _getDoctorName(context, visit.doctorId) ?? 'Неизвестно';
      if (!context.mounted) return;
      final serviceName =
          await _getServiceName(context, visit) ?? 'Неизвестная услуга';
      final patientName =
          '${user.surname} ${user.name} ${user.patronymic ?? ''}'.trim();

      await recordsRepo.sendVisitReportEmailGmail(
        toEmail: toEmail,
        patientName: patientName,
        doctorName: doctorName,
        serviceName: serviceName,
        date: visit.date,
        time: visit.time,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Письмо успешно отправлено на вашу почту'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отправить письмо: $e')),
      );
    }
  }

  Future<String?> _getPatientName(
    BuildContext context,
    String patientId,
  ) async {
    try {
      final recordsRepo = RepositoryProvider.of<RecordsRepository>(context);
      return await recordsRepo.getPatientName(patientId);
    } catch (e) {
      return 'Неизвестно';
    }
  }

  Future<String?> _getDoctorName(BuildContext context, String doctorId) async {
    try {
      final recordsRepo = RepositoryProvider.of<RecordsRepository>(context);
      return await recordsRepo.getDoctorName(doctorId);
    } catch (e) {
      return 'Неизвестно';
    }
  }

  Future<String?> _getServiceName(
    BuildContext context,
    VisitModel visit,
  ) async {
    try {
      final recordsRepo = RepositoryProvider.of<RecordsRepository>(context);
      return await recordsRepo.getServiceName(visit);
    } catch (e) {
      return 'Неизвестно';
    }
  }

  void _showTreatmentDialog(BuildContext context, VisitModel visit) {
    final diagnosisController = TextEditingController();
    final recommendationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Назначить лечение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Диагноз',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recommendationController,
              decoration: const InputDecoration(
                labelText: 'Рекомендации',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (diagnosisController.text.isNotEmpty &&
                  recommendationController.text.isNotEmpty) {
                context.read<RecordsBloc>().add(
                  RecordsCreatePatientCard(
                    patientId: visit.userId,
                    doctorId: user.id,
                    diagnosis: diagnosisController.text,
                    recommendation: recommendationController.text,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Лечение назначено')),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: const Text('Назначить'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} года';
  }

  String _formatTime(DateTime time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
