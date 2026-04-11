import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../config/supabase_config.dart';

/// Servicio de administración que usa Supabase Edge Functions.
/// La Service Role Key vive en el servidor (Supabase secrets), nunca en el cliente.
///
/// IMPORTANTE: supabase_flutter 2.x inyecta el JWT automáticamente en
/// functions.invoke(). NO agregar headers Authorization manuales.
class AdminSupabaseService {
  final _client = SupabaseConfig.client;

  /// Refresca la sesión para asegurar un JWT válido antes de cada llamada.
  Future<void> _ensureFreshToken() async {
    try {
      await _client.auth.refreshSession();
    } catch (e) {
      print('[AdminService] Warning: could not refresh session: $e');
    }
  }

  Future<List<AppUser>> listUsers() async {
    try {
      await _ensureFreshToken();

      final response = await _client.rpc('get_all_users');
      final users = response as List<dynamic>;

      print('[AdminService] Found ${users.length} users via RPC');
      return users.map((u) => AppUser.fromMap(u as Map<String, dynamic>)).toList();
    } catch (e) {
      print('[AdminService] ERROR listing users: $e');
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
      await _ensureFreshToken();
      final response = await _client.rpc(
        'admin_create_user',
        params: {'new_email': email, 'new_password': password, 'new_role': role, 'new_name': name},
      );
      print('[AdminService] createUser RPC successful');
      return true;
    } catch (e) {
      print('[AdminService] Error creating user: $e');
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
      await _ensureFreshToken();
      final response = await _client.rpc(
        'admin_update_user',
        params: {
          'target_user_id': id,
          if (password != null && password.isNotEmpty) 'new_password': password,
          if (role != null) 'new_role': role,
          if (name != null) 'new_name': name,
        },
      );
      print('[AdminService] updateUser RPC successful');
      return true;
    } catch (e) {
      print('[AdminService] Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    try {
      await _ensureFreshToken();
      final response = await _client.rpc(
        'admin_delete_user',
        params: {'target_user_id': id},
      );
      print('[AdminService] deleteUser RPC successful');
      return true;
    } catch (e) {
      print('[AdminService] Error deleting user: $e');
      return false;
    }
  }
}
