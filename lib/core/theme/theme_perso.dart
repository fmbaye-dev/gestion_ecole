import 'package:flutter/material.dart';

abstract class ThemePerso {
  // Couleurs du logo
  static const Color bleuPrincipal = Color(0xFF1A3A8F);
  static const Color bleuFonce = Color(0xFF0D1B3E);
  static const Color bleuTresFonce = Color(0xFF0A1428);
  static const Color bleuClair = Color(0xFF4A90D9);
  static const Color bleuCiel = Color(0xFF6BB3F0);
  static const Color or = Color(0xFFD4A843);

  //! MODE CLAIR
  static final ThemeData modeClair = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme(
      brightness: Brightness.light,

      primary: bleuPrincipal,
      onPrimary: Colors.white,

      secondary: or,
      onSecondary: Colors.white,

      surface: Colors.white,
      onSurface: Colors.black87,

      error: Colors.red,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: bleuPrincipal,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bleuPrincipal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: bleuPrincipal, width: 2),
      ),
    ),
  );

  //! MODE SOMBRE
  static final ThemeData modeSombre = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: ColorScheme(
      brightness: Brightness.dark,

      primary: bleuClair,
      onPrimary: Colors.white,

      secondary: or,
      onSecondary: Colors.black,

      surface: bleuFonce,
      onSurface: Colors.white,

      error: Colors.redAccent,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: bleuFonce,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bleuClair,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: bleuClair, width: 2),
      ),
    ),
  );
}
