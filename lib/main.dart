import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/qr_edit_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/fugas_provider.dart';

// 2. Definimos la clase para ignorar errores de certificados SSL
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Solo en plataformas nativas (dart:io no existe en web)
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
  
  // Load environment variables (solo en plataformas nativas, no en web)
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // .env no encontrado — ok, ya no se requiere en runtime
    }
  }
  
  // Initialize Supabase
  await SupabaseConfig.init();
  
  // Initialize date formatting
  await initializeDateFormatting('es_ES', null);

  int? initialFugaId;
  if (kIsWeb) {
    final fugaIdStr = Uri.base.queryParameters['fuga_id'];
    if (fugaIdStr != null) {
      initialFugaId = int.tryParse(fugaIdStr);
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        pendingFugaIdProvider.overrideWith(() => PendingFugaIdNotifier(initialFugaId)),
      ],
      child: const LeakHunterApp(),
    ),
  );
}

class LeakHunterApp extends ConsumerWidget {
  const LeakHunterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final pendingId = ref.watch(pendingFugaIdProvider);

    if (authState.user == null) {
      return MaterialApp(
        title: 'Leak Hunter v4.2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const LoginScreen(),
      );
    }

    if (pendingId != null) {
      return MaterialApp(
        title: 'Leak Hunter v4.2',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: QREditScreen(fugaId: pendingId),
      );
    }

    return MaterialApp(
      title: 'Leak Hunter v4.2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}