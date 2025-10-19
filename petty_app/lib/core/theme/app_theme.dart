import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColor: Colors.cyan[600],
  scaffoldBackgroundColor: Colors.cyan[50],
  colorScheme: ColorScheme.light(
    primary: Colors.cyan[600]!,
    secondary: Colors.cyan[400]!,
    surface: Colors.white,
    error: Colors.red[400]!,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.cyan[600],
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    surfaceTintColor: Colors.transparent, // prevents M3 tint overlay
    color: Colors.white, // explicit background color
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.cyan[300]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.cyan[200]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.cyan[600]!, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    hintStyle: TextStyle(color: Colors.grey[600]),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.cyan,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.cyan[700],
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  primaryColor: Colors.cyan[400],
  scaffoldBackgroundColor: Colors.grey[900],
  colorScheme: ColorScheme.dark(
    primary: Colors.cyan[400]!,
    secondary: Colors.cyan[300]!,
    surface: Colors.grey[850]!,
    error: Colors.red[400]!,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.cyan[700],
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    surfaceTintColor: Colors.transparent,
    color: Colors.grey[850],
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.cyan[600]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey[700]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.cyan[400]!, width: 2),
    ),
    filled: true,
    fillColor: Colors.grey[800],
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    hintStyle: TextStyle(color: Colors.grey[400]),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.cyan,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.cyanAccent,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);
