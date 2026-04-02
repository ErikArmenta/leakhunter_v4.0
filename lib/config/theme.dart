import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0e1117);
  static const Color cardBackground = Color(0xFF161a22);
  static const Color borderColor = Color(0xFF2d323d);
  static const Color textPrimary = Color(0xFFfafafa);
  static const Color textSecondary = Color(0xFF888888);
  static const Color primaryAccent = Color(0xFF5271ff);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        surface: cardBackground,
        background: background,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontFamily: 'Segoe UI'),
        bodyMedium: TextStyle(color: textPrimary, fontFamily: 'Segoe UI'),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI'),
        titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontFamily: 'Segoe UI'),
        bodySmall: TextStyle(color: textSecondary, fontFamily: 'Segoe UI'),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBackground,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryAccent),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Segoe UI'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryAccent,
          side: const BorderSide(color: primaryAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryAccent),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: cardBackground,
        selectedIconTheme: IconThemeData(color: primaryAccent),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        selectedLabelTextStyle: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBackground,
        indicatorColor: primaryAccent.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(color: primaryAccent, fontWeight: FontWeight.bold);
          }
          return const TextStyle(color: textSecondary);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const IconThemeData(color: primaryAccent);
          }
          return const IconThemeData(color: textSecondary);
        }),
      ),
    );
  }
}
