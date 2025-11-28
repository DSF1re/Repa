import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class DoctorsRepository {
  final _supabase = Supabase.instance.client;

  Future<List<UserModel>> getDoctors() async {
    final response = await _supabase
        .from('User')
        .select()
        .eq('Role', 'Доктор')
        .neq('Status', 'Не активен')
        .order('Surname', ascending: true);

    return (response as List)
        .map((doctor) => UserModel.fromJson(doctor))
        .toList();
  }

  Future<UserModel> updateDoctor(UserModel doctor) async {
    await _supabase
        .from('User')
        .update(doctor.toJson())
        .eq('ID_User', doctor.id);

    return doctor;
  }

  Future<void> deactivateDoctor(String doctorId) async {
    await _supabase
        .from('User')
        .update({'Status': 'Не активен'})
        .eq('ID_User', doctorId);
  }
}
