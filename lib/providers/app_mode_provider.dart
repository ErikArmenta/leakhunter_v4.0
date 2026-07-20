import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AppModeNotifier extends Notifier<AppMode> {
  static const _key = 'app_mode_key';

  @override
  AppMode build() {
    _loadFromPrefs();
    return AppMode.fugas; // Default value while loading
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_key);
    
    if (modeString != null) {
      final mode = AppMode.values.firstWhere(
        (e) => e.toString() == modeString,
        orElse: () => AppMode.fugas,
      );
      state = mode;
    }
  }

  Future<void> setMode(AppMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.toString());
  }
}

final appModeProvider = NotifierProvider<AppModeNotifier, AppMode>(() {
  return AppModeNotifier();
});
