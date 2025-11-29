import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/visit_model.dart';

class RecordsRepository {
  final SupabaseClient _supabaseClient;

  RecordsRepository({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  Future<bool> _hasTreatmentForPatient(String patientId) async {
    final response = await _supabaseClient
        .from('Patient_Card')
        .select('ID_PCard')
        .eq('ID_Patient', patientId)
        .limit(1)
        .maybeSingle();

    return response != null;
  }

  Future<void> sendVisitReportEmailGmail({
    required String toEmail,
    required String patientName,
    required String doctorName,
    required String serviceName,
    required DateTime date,
    required DateTime time,
  }) async {
    const username = 'gaisinvildan6@gmail.com';
    const appPassword = 'iwkj fihg cczt qqwu';

    final smtpServer = gmail(username, appPassword);

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final formattedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    final message = Message()
      ..from = Address(username, 'Ваша клиника')
      ..recipients.add(toEmail)
      ..subject = 'Документ об оказанных услугах $formattedDate'
      ..html =
          '''
<h2>Документ об оказанных медицинских услугах</h2>
<p><b>Пациент:</b> $patientName</p>
<p><b>Врач:</b> $doctorName</p>
<p><b>Дата и время приема:</b> $formattedDate $formattedTime</p>
<p><b>Услуга:</b> $serviceName</p>
<p>Спасибо за обращение в нашу клинику.</p>
''';

    await send(message, smtpServer);
  }

  Future<List<VisitModel>> getDoctorVisits(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from('Vizit')
          .select('*')
          .eq('ID_Doctor', doctorId)
          .order('Date_Vizit', ascending: true)
          .order('Time_Vizit', ascending: true);

      final visits = <VisitModel>[];

      for (final json in response as List) {
        var visit = VisitModel.fromJson(json as Map<String, dynamic>);
        final hasTreatment = await _hasTreatmentForPatient(visit.userId);
        visit = visit.copyWith(hasTreatment: hasTreatment);
        visits.add(visit);
      }

      return visits;
    } catch (e) {
      throw Exception('Ошибка загрузки записей: $e');
    }
  }

  Future<bool> _hasTreatmentForVisit(int visitId, String patientId) async {
    final response = await _supabaseClient
        .from('Issue')
        .select('ID_Issue, Patient_Card!inner(ID_Patient, Diagnosis)')
        .eq('ID_Vizit', visitId)
        .eq('Patient_Card.ID_Patient', patientId)
        .maybeSingle();

    return response != null;
  }

  Future<List<VisitModel>> getPatientVisits(String patientId) async {
    try {
      final response = await _supabaseClient
          .from('Vizit')
          .select('*')
          .eq('ID_User', patientId)
          .order('Date_Vizit', ascending: true)
          .order('Time_Vizit', ascending: true);

      final visits = <VisitModel>[];

      for (final json in response as List) {
        var visit = VisitModel.fromJson(json as Map<String, dynamic>);
        final has = await _hasTreatmentForVisit(visit.id, patientId);
        visit = visit.copyWith(hasTreatment: has);
        visits.add(visit);
      }

      return visits;
    } catch (e) {
      throw Exception('Ошибка загрузки записей: $e');
    }
  }

  /// Создание карточки пациента
  Future<PatientCardModel> createPatientCard({
    required String patientId,
    required String diagnosis,
    required String recommendation,
  }) async {
    try {
      final response = await _supabaseClient
          .from('Patient_Card')
          .insert({
            'ID_Patient': patientId,
            'Diagnosis': diagnosis,
            'Recomendation': recommendation,
          })
          .select('*')
          .single();

      return PatientCardModel.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка создания карточки пациента: $e');
    }
  }

  /// Получение имени пациента по ID
  Future<String?> getPatientName(String patientId) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('Surname, Name, Patronymic')
          .eq('ID_User', patientId)
          .maybeSingle();

      if (response == null) return null;
      final surname = response['Surname'] as String? ?? '';
      final name = response['Name'] as String? ?? '';
      final patronymic = response['Patronymic'] as String? ?? '';
      return '$surname $name $patronymic'.trim();
    } catch (e) {
      return null;
    }
  }

  /// Получение имени доктора по ID
  Future<String?> getDoctorName(String doctorId) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('Surname, Name, Patronymic')
          .eq('ID_User', doctorId)
          .maybeSingle();

      if (response == null) return null;
      final surname = response['Surname'] as String? ?? '';
      final name = response['Name'] as String? ?? '';
      final patronymic = response['Patronymic'] as String? ?? '';
      return '$surname $name $patronymic'.trim();
    } catch (e) {
      return null;
    }
  }

  Future<String?> getServiceName(VisitModel visit) async {
    try {
      final response = await _supabaseClient
          .from('Issue')
          .select('Service(Name)')
          .eq('ID_Vizit', visit.id)
          .maybeSingle();

      if (response == null) return null;
      final serviceData = response['Service'] as Map<String, dynamic>?;
      return serviceData?['Name'] as String? ?? 'Неизвестная услуга';
    } catch (e) {
      return 'Неизвестная услуга';
    }
  }
}
