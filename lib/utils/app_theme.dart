import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1DB954); // Spotify green
  static const Color primaryDark = Color(0xFF169C46);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  static const Color cardColor = Color(0xFF282828);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFCF6679);
  static const Color vote = Color(0xFF1DB954);
  static const Color downvote = Color(0xFFE74C3C);
  static const Color accent = Color(0xFF1ED760);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.onBackground,
        onError: Colors.white,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.onBackground),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurface,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.onSurface),
        hintStyle: const TextStyle(color: AppColors.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.surfaceVariant),
      iconTheme: const IconThemeData(color: AppColors.onSurface),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.onBackground),
        titleSmall: TextStyle(color: AppColors.onSurface),
        bodyLarge: TextStyle(color: AppColors.onBackground),
        bodyMedium: TextStyle(color: AppColors.onSurface),
        bodySmall: TextStyle(color: AppColors.onSurface, fontSize: 12),
        labelLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600),
      ),
    );
  }
}
