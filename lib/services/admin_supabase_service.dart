import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../config/supabase_config.dart';

/// Servicio de administración que usa Supabase Edge Functions.
/// La Service Role Key vive en el servidor (Supabase secrets), nunca en el cliente.
class AdminSupabaseService {
  final _client = SupabaseConfig.client;

  Future<List<AppUser>> listUsers() async {
    try {
      final response = await _client.functions.invoke(
        'admin-list-users',
        method: HttpMethod.get,
        headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'},
      );
      final data = response.data as Map<String, dynamic>;
      final users = data['users'] as List<dynamic>;
      return users.map((u) => AppUser.fromMap(u as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error listing users: $e');
      return [];
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String role,
    required String name,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-create-user',
        headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'},
        body: {'email': email, 'password': password, 'role': role, 'name': name},
      );
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUser(
    String id, {
    String? password,
    String? role,
    String? name,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'admin-update-user',
        headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'},
        body: {
          'id': id,
          if (password != null && password.isNotEmpty) 'password': password,
          if (role != null) 'role': role,
          if (name != null) 'name': name,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      final response = await _client.functions.invoke(
        'admin-delete-user',
        headers: {'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}'},
        body: {'id': id},
      );
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
