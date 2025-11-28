import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduleRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSchedules() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final response = await _supabase
        .from('Schedule')
        .select('''
        *,
        User!inner(Surname, Name, Patronymic, Specialization),
        Cabinet!inner(ID_Cabinet, Name)
      ''')
        .gte('Date', today)
        .order('Date', ascending: true)
        .order('Time_Start', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getDoctors() async {
    final response = await _supabase
        .from('User')
        .select('ID_User, Surname, Name, Patronymic, Specialization')
        .eq('Role', 'Доктор')
        .eq('Status', 'Активен')
        .order('Surname', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getCabinets() async {
    final response = await _supabase
        .from('Cabinet')
        .select('*')
        .order('Name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addSchedule(Map<String, dynamic> scheduleData) async {
    await _supabase.from('Schedule').insert(scheduleData);
  }

  Future<void> deleteSchedule(int scheduleId) async {
    await _supabase.from('Schedule').delete().eq('ID_Schedule', scheduleId);
  }
}
