import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final String role;
  final String name;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.role = 'Inspector',
    this.name = 'Sin Nombre',
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    String? role,
    String? name,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      role: role ?? this.role,
      name: name ?? this.name,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _supabase = SupabaseConfig.client;

  @override
  AuthState build() {
    final user = _supabase.auth.currentUser;

    // Cargar datos desde public.users si hay sesión activa
    if (user != null) {
      Future.microtask(() => _loadAndSetUserData(user));
    }

    // Escuchar cambios de sesión
    Future.microtask(() {
      _supabase.auth.onAuthStateChange.listen((data) async {
        final sessionUser = data.session?.user;
        if (sessionUser != null) {
          await _loadAndSetUserData(sessionUser);
        } else {
          state = AuthState(); // Logout → reset
        }
      });
    });

    return AuthState(user: user);
  }

  /// Lee role y name desde public.users, con fallback a raw_user_meta_data.
  Future<void> _loadAndSetUserData(User user) async {
    try {
      // 1. Intentar leer de public.users (tabla real del proyecto)
      final row = await _supabase
          .from('users')
          .select('name, role')
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        state = AuthState(
          user: user,
          isLoading: false,
          role: (row['role'] as String?)?.trim().isNotEmpty == true
              ? row['role'] as String
              : 'Inspector',
          name: (row['name'] as String?)?.trim().isNotEmpty == true
              ? row['name'] as String
              : _nameFromMeta(user),
        );
        return;
      }

      // 2. No hay fila en public.users → insertar con datos de metadata
      final name = _nameFromMeta(user);
      final role = _roleFromMeta(user);

      try {
        await _supabase.from('users').insert({
          'id': user.id,
          'email': user.email ?? '',
          'name': name,
          'role': role,
        });
      } catch (insertErr) {
        // Puede ser conflict si ya se insertó por race condition — no es fatal
        print('[AuthProvider] Insert users row (posible conflict): $insertErr');
      }

      state = AuthState(
        user: user,
        isLoading: false,
        role: role,
        name: name,
      );
    } catch (e) {
      print('[AuthProvider] Error cargando datos de usuario: $e');
      // Fallback a metadata pura para no bloquear el login
      state = AuthState(
        user: user,
        isLoading: false,
        role: _roleFromMeta(user),
        name: _nameFromMeta(user),
      );
    }
  }

  String _nameFromMeta(User user) {
    final meta = user.userMetadata ?? {};
    return (meta['full_name'] as String?)?.trim().isNotEmpty == true
        ? meta['full_name'] as String
        : (meta['name'] as String?)?.trim().isNotEmpty == true
            ? meta['name'] as String
            : user.email?.split('@').first ?? 'Usuario';
  }

  String _roleFromMeta(User user) {
    final meta = user.userMetadata ?? {};
    return (meta['role'] as String?)?.trim().isNotEmpty == true
        ? meta['role'] as String
        : 'Inspector';
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // El listener onAuthStateChange llama _loadAndSetUserData automáticamente
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ocurrió un error inesperado');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _supabase.auth.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);