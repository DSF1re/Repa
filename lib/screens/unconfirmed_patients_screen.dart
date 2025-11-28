import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/unconfirmed_patients/unconfirmed_patients_bloc.dart';

class UnconfirmedPatientsScreen extends StatefulWidget {
  const UnconfirmedPatientsScreen({super.key});

  @override
  State<UnconfirmedPatientsScreen> createState() =>
      _UnconfirmedPatientsScreenState();
}

class _UnconfirmedPatientsScreenState extends State<UnconfirmedPatientsScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ Загружаем данные при первом открытии
    _refreshData();

    // ✅ Устанавливаем таймер на обновление каждые 5 секунд
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel(); // ✅ Отменяем таймер при выходе
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ Обновляем данные при каждом входе на экран
    _refreshData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ✅ Обновляем при возврате в приложение
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  void _refreshData() {
    if (mounted) {
      context.read<UnconfirmedPatientsBloc>().add(
        const UnconfirmedPatientsLoadRequested(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const UnconfirmedPatientsView();
  }
}

class UnconfirmedPatientsView extends StatelessWidget {
  const UnconfirmedPatientsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<UnconfirmedPatientsBloc, UnconfirmedPatientsState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: BlocBuilder<UnconfirmedPatientsBloc, UnconfirmedPatientsState>(
          builder: (context, state) {
            switch (state.status) {
              case UnconfirmedPatientsStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case UnconfirmedPatientsStatus.failure:
                return _buildErrorState(context);
              case UnconfirmedPatientsStatus.success:
                if (state.patients.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildPatientsListWithRefresh(state.patients, context);
              case UnconfirmedPatientsStatus.initial:
                return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<UnconfirmedPatientsBloc>().add(
            const UnconfirmedPatientsLoadRequested(),
          );
        },
        child: Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Ошибка загрузки пациентов',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<UnconfirmedPatientsBloc>().add(
                const UnconfirmedPatientsLoadRequested(),
              );
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет неподтвержденных пациентов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Все пациенты подтверждены',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          Text(
            'Автообновление каждые 5 секунд',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Добавлен Pull-to-Refresh для ручного обновления
  Widget _buildPatientsListWithRefresh(
    List<Map<String, dynamic>> patients,
    context,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<UnconfirmedPatientsBloc>().add(
          const UnconfirmedPatientsLoadRequested(),
        );

        // Ждем завершения загрузки
        await context.read<UnconfirmedPatientsBloc>().stream.firstWhere(
          (state) => state.status != UnconfirmedPatientsStatus.loading,
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return UnconfirmedPatientTile(patient: patient);
        },
      ),
    );
  }
}

class UnconfirmedPatientTile extends StatelessWidget {
  final Map<String, dynamic> patient;

  const UnconfirmedPatientTile({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final surname = patient['Surname'] ?? '';
    final name = patient['Name'] ?? '';
    final patronymic = patient['Patronymic'] ?? '';
    final email = patient['Email'] ?? '';
    final passport = patient['Passport'] ?? '';
    final birthday = patient['BDay'] ?? '';
    final fullName = '$surname $name $patronymic';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: Icon(Icons.person_add, color: Colors.orange.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Ожидает подтверждения',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', email),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.credit_card, 'Паспорт', passport),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.cake, 'Дата рождения', birthday),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Отклонить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        _showRejectDialog(context, patient['ID_User']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Подтвердить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        _showConfirmDialog(context, patient['ID_User']),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _showConfirmDialog(BuildContext context, String patientId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Подтверждение регистрации'),
        content: const Text(
          'Вы уверены, что хотите подтвердить регистрацию этого пациента?\n\nПациент получит доступ к системе.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<UnconfirmedPatientsBloc>().add(
                PatientConfirmRequested(patientId),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Пациент успешно подтвержден'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String patientId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.cancel, color: Colors.red, size: 48),
        title: const Text('Отклонение регистрации'),
        content: const Text(
          'Вы уверены, что хотите отклонить регистрацию этого пациента?\n\nПациент не сможет войти в систему.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<UnconfirmedPatientsBloc>().add(
                PatientRejectRequested(patientId),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Регистрация пациента отклонена'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }
}
