import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRepository {
  final SupabaseClient _db;
  BookingRepository(this._db);

  Future<List<Map<String, dynamic>>> getDoctorsWithScheduleForDate({
    required String specializationRu,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await _db
        .from('Schedule')
        .select(
          'User!inner(ID_User, Surname, Name, Patronymic, Specialization, Status), Date, Time_Start, Time_End',
        )
        .eq('Date', dateStr)
        .eq('User.Specialization', specializationRu)
        .eq('User.Status', 'Активен')
        .order('Time_Start', ascending: true);
    final seen = <String>{};
    final doctors = <Map<String, dynamic>>[];
    for (final r in rows as List) {
      final user = r['User'];
      if (user != null && !seen.contains(user['ID_User'])) {
        seen.add(user['ID_User']);
        doctors.add(user as Map<String, dynamic>);
      }
    }
    return doctors;
  }

  Future<List<Map<String, dynamic>>> getSchedulesForDoctorDate({
    required String doctorId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await _db
        .from('Schedule')
        .select('ID_Schedule, Date, Time_Start, Time_End, ID_Doctor')
        .eq('Date', dateStr)
        .eq('ID_Doctor', doctorId)
        .order('Time_Start', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Set<String>> getBookedTimes({
    required String doctorId,
    required DateTime date,
  }) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final rows = await _db
        .from('Vizit')
        .select('Time_Vizit')
        .eq('ID_Doctor', doctorId)
        .eq('Date_Vizit', dateStr);
    return rows.map((e) => (e['Time_Vizit'] as String).substring(0, 5)).toSet();
  }

  Future<int> getOrCreatePatientCard(String patientId) async {
    final existing = await _db
        .from('Patient_Card')
        .select('ID_PCard')
        .eq('ID_Patient', patientId)
        .maybeSingle();
    if (existing != null) return existing['ID_PCard'] as int;
    final inserted = await _db
        .from('Patient_Card')
        .insert({'ID_Patient': patientId})
        .select('ID_PCard')
        .single();
    return inserted['ID_PCard'] as int;
  }

  Future<int> createVizit({
    required String patientId,
    required String doctorId,
    required DateTime date,
    required String hhmm,
  }) async {
    final resp = await _db
        .from('Vizit')
        .insert({
          'ID_User': patientId,
          'ID_Doctor': doctorId,
          'Date_Vizit': date.toIso8601String().substring(0, 10),
          'Time_Vizit': '$hhmm:00',
        })
        .select('ID_Vizit')
        .single();
    return resp['ID_Vizit'] as int;
  }

  Future<int> createIssue({
    required int pcardId,
    required int vizitId,
    required int serviceId,
  }) async {
    final resp = await _db
        .from('Issue')
        .insert({
          'ID_PCard': pcardId,
          'ID_Vizit': vizitId,
          'ID_Service': serviceId,
        })
        .select('ID_Issue')
        .single();
    return resp['ID_Issue'] as int;
  }

  Future<int> createPayment({
    required int vizitId,
    required String methodRu,
  }) async {
    final resp = await _db
        .from('Payment')
        .insert({
          'ID_Vizit': vizitId,
          'Date_GetPay': DateTime.now().toIso8601String().substring(0, 10),
          'Method': methodRu,
        })
        .select('ID_Payment')
        .single();
    return resp['ID_Payment'] as int;
  }
}
