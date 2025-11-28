import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';

class ServiceRepository {
  final SupabaseClient _supabaseClient;

  ServiceRepository({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  Future<List<ServiceModel>> getServices() async {
    final response = await _supabaseClient.from('Service').select();

    return (response as List)
        .map((json) => ServiceModel.fromJson(json))
        .toList();
  }
}
