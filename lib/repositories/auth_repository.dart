import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Ошибка авторизации');
    }

    if (response.user!.emailConfirmedAt == null) {
      throw Exception('Подтвердите email для завершения регистрации');
    }

    final userData = await getUserData(response.user!.id);
    return userData;
  }

  Future<UserModel> getUserData(String userId) async {
    final response = await _supabase
        .from('User')
        .select()
        .eq('ID_User', userId)
        .single();

    if (response['Status'] == 'Не подтвержден') {
      throw Exception('Ожидайте подтверждение регистрации администратором');
    }

    return UserModel.fromJson(response);
  }

  Future<void> signUp({required String email, required String password}) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Ошибка регистрации');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
