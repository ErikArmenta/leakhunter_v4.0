import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../services/admin_supabase_service.dart';

final adminSupabaseServiceProvider = Provider<AdminSupabaseService>((ref) {
  return AdminSupabaseService();
});

class AdminUsersNotifier extends AsyncNotifier<List<AppUser>> {
  late AdminSupabaseService _service;

  @override
  Future<List<AppUser>> build() async {
    _service = ref.watch(adminSupabaseServiceProvider);
    return _service.listUsers();
  }

  Future<void> reloadUsers() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.listUsers());
  }

  Future<bool> createUser({required String email, required String password, required String role, required String name}) async {
    final success = await _service.createUser(email: email, password: password, role: role, name: name);
    if (success) {
      await reloadUsers();
    }
    return success;
  }

  Future<bool> updateUser(String id, {String? password, String? role, String? name}) async {
    final success = await _service.updateUser(id, password: password, role: role, name: name);
    if (success) {
      await reloadUsers();
    }
    return success;
  }

  Future<bool> deleteUser(String id) async {
    final success = await _service.deleteUser(id);
    if (success) {
      await reloadUsers();
    }
    return success;
  }
}

final adminUsersProvider = AsyncNotifierProvider<AdminUsersNotifier, List<AppUser>>(() {
  return AdminUsersNotifier();
});
