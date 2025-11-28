import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserRepository {
  final SupabaseClient _supabaseClient;

  UserRepository({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  /// Получение всех активных докторов
  Future<List<UserModel>> getDoctors() async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .eq('Role', 'Доктор')
          .neq('Status', 'Не активен')
          .order('Surname', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки докторов: $e');
    }
  }

  /// Получение всех активных пациентов
  Future<List<UserModel>> getPatients() async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .eq('Role', 'Пациент')
          .neq('Status', 'Не активен')
          .order('Surname', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки пациентов: $e');
    }
  }

  /// Получение неподтвержденных пациентов
  Future<List<UserModel>> getUnconfirmedPatients() async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .eq('Role', 'Пациент')
          .eq('Status', 'Не подтвержден')
          .order('Surname', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки неподтвержденных пациентов: $e');
    }
  }

  /// Получение неподтвержденных пациентов в виде Map (для совместимости с блоком)
  Future<List<Map<String, dynamic>>> getUnconfirmedPatientsAsMap() async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .eq('Role', 'Пациент')
          .eq('Status', 'Не подтвержден')
          .order('Surname', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Ошибка загрузки неподтвержденных пациентов: $e');
    }
  }

  /// Получение пользователя по ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .eq('ID_User', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка получения пользователя: $e');
    }
  }

  /// Обновление пользователя
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .update(user.toJson())
          .eq('ID_User', user.id)
          .select('*')
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка обновления пользователя: $e');
    }
  }

  /// Деактивация пользователя
  Future<void> deactivateUser(String userId) async {
    try {
      await _supabaseClient
          .from('User')
          .update({'Status': 'Не активен'})
          .eq('ID_User', userId);
    } catch (e) {
      throw Exception('Ошибка деактивации пользователя: $e');
    }
  }

  /// Подтверждение пациента (активация)
  Future<void> confirmPatient(String userId) async {
    try {
      await _supabaseClient
          .from('User')
          .update({'Status': 'Активен'})
          .eq('ID_User', userId);
    } catch (e) {
      throw Exception('Ошибка подтверждения пациента: $e');
    }
  }

  /// Отклонение регистрации пациента
  Future<void> rejectPatient(String userId) async {
    try {
      await _supabaseClient
          .from('User')
          .update({'Status': 'Отклонен'})
          .eq('ID_User', userId);
    } catch (e) {
      throw Exception('Ошибка отклонения пациента: $e');
    }
  }

  /// Создание нового пользователя
  Future<UserModel> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .insert(userData)
          .select('*')
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Ошибка создания пользователя: $e');
    }
  }

  /// Удаление пользователя (окончательное удаление)
  Future<void> deleteUser(String userId) async {
    try {
      await _supabaseClient.from('User').delete().eq('ID_User', userId);
    } catch (e) {
      throw Exception('Ошибка удаления пользователя: $e');
    }
  }

  /// Получение пользователей по роли
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .eq('Role', role)
          .neq('Status', 'Не активен')
          .order('Surname', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки пользователей по роли: $e');
    }
  }

  /// Получение пользователей по статусу
  Future<List<UserModel>> getUsersByStatus(String status) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .eq('Status', status)
          .order('Surname', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка загрузки пользователей по статусу: $e');
    }
  }

  /// Поиск пользователей по имени/фамилии
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('*')
          .or(
            'Surname.ilike.%$query%,Name.ilike.%$query%,Patronymic.ilike.%$query%',
          )
          .neq('Status', 'Не активен')
          .order('Surname', ascending: true);

      return (response as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Ошибка поиска пользователей: $e');
    }
  }

  /// Проверка существования пользователя по email
  Future<bool> userExistsByEmail(String email) async {
    try {
      final response = await _supabaseClient
          .from('User')
          .select('ID_User')
          .eq('Email', email)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Ошибка проверки существования пользователя: $e');
    }
  }

  /// Обновление статуса пользователя
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _supabaseClient
          .from('User')
          .update({'Status': status})
          .eq('ID_User', userId);
    } catch (e) {
      throw Exception('Ошибка обновления статуса пользователя: $e');
    }
  }
}
