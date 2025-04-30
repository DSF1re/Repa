import 'package:flutter/material.dart';
import 'main.dart';

class UnconfirmedPatientsScreen extends StatefulWidget {
  const UnconfirmedPatientsScreen({super.key});

  @override
  State<UnconfirmedPatientsScreen> createState() =>
      _UnconfirmedPatientsScreenState();
}

class _UnconfirmedPatientsScreenState extends State<UnconfirmedPatientsScreen> {
  late Future<List<Map<String, dynamic>>> _unconfirmedPatients;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUnconfirmedPatients();
  }

  Future<void> _fetchUnconfirmedPatients() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('User')
          .select()
          .eq('Role', 'Пациент')
          .eq('Status', 'Не подтвержден');

      if (!mounted) return;

      setState(() {
        _unconfirmedPatients = Future.value(
          List<Map<String, dynamic>>.from(response as List),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmPatient(String userId) async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      await supabase
          .from('User')
          .update({'Status': 'Активен'})
          .eq('ID_User', userId);

      await _fetchUnconfirmedPatients();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пациент подтвержден')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<Map<String, dynamic>>>(
                future: _unconfirmedPatients,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Нет неподтвержденных пациентов'),
                    );
                  }

                  final patients = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            '${patient['Surname']} ${patient['Name']} ${patient['Patronymic'] ?? ''}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: ${patient['Email']}'),
                              Text('Паспорт: ${patient['Passport']}'),
                              Text('Дата рождения: ${patient['BDay']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed:
                                () => _confirmPatient(patient['ID_User']),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
