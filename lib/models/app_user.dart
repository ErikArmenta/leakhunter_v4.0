import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String email;
  final String role;
  final String name;
  final DateTime? createdAt;
  final DateTime? lastSignInAt;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.createdAt,
    this.lastSignInAt,
  });

  factory AppUser.fromAuthUser(User user) {
    final metadata = user.userMetadata ?? {};
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      role: metadata['role'] as String? ?? 'Inspector',
      name: metadata['full_name'] as String? ?? 'Sin nombre',
      createdAt: DateTime.tryParse(user.createdAt),
      lastSignInAt: user.lastSignInAt != null ? DateTime.tryParse(user.lastSignInAt!) : null,
    );
  }

  /// Parsea la respuesta JSON que retorna la Edge Function admin-list-users o de la función RPC
  factory AppUser.fromMap(Map<String, dynamic> map) {
    final metadata = map['user_metadata'] as Map<String, dynamic>? ?? {};
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: metadata['role'] as String? ?? map['role'] as String? ?? 'Inspector',
      name: metadata['full_name'] as String? ?? map['name'] as String? ?? 'Sin nombre',
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      lastSignInAt: map['last_sign_in_at'] != null ? DateTime.tryParse(map['last_sign_in_at']) : null,
    );
  }
}
