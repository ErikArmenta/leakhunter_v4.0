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
  @override
  AuthState build() {
    // 1. Obtenemos el usuario inicial
    final user = SupabaseConfig.client.auth.currentUser;
    final metadata = user?.userMetadata ?? {};

    // 2. Escuchamos cambios de sesión. 
    // Usamos un delay de microtarea para no interferir con la creación del Provider
    Future.microtask(() {
      SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
        final sessionUser = data.session?.user;
        final md = sessionUser?.userMetadata ?? {};
        state = AuthState(
          user: sessionUser, 
          isLoading: false,
          role: md['role'] as String? ?? 'Inspector',
          name: md['full_name'] as String? ?? 'Sin Nombre',
        );
      });
    });

    return AuthState(
      user: user,
      role: metadata['role'] as String? ?? 'Inspector',
      name: metadata['full_name'] as String? ?? 'Sin Nombre',
    );
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // No hace falta setear el usuario aquí, 
      // el listener de onAuthStateChange lo hará por ti automáticamente.
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ocurrió un error inesperado');
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await SupabaseConfig.client.auth.signOut();
  }
}

// 3. Corregimos la declaración del Provider (sintaxis simplificada)
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);