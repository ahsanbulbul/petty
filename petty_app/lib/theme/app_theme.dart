import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.green[600],
  scaffoldBackgroundColor: Colors.green[50],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.green[600],
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    hintStyle: TextStyle(color: Colors.grey[700]),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.black),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25), // added horizontal padding
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
  ),
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.green[400],
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.green[700],
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: Colors.grey[800],
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
    hintStyle: TextStyle(color: Colors.grey[400]),
  ),
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green[400],
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
  ),
);
