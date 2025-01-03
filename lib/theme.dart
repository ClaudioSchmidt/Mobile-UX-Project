import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
  ),
  // Additional color options
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black54),
    titleMedium: TextStyle(color: Colors.grey),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[300]!,
    selectedColor: Colors.green,
    labelStyle: const TextStyle(color: Colors.black),
  ),
  cardColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  dialogBackgroundColor: Colors.white,
);

final ThemeData darkTheme = ThemeData(
  primarySwatch: Colors.blue,
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.blue,
  ),
  // Additional color options
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    titleMedium: TextStyle(color: Colors.grey),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.grey[800]!,
    selectedColor: Colors.green,
    labelStyle: const TextStyle(color: Colors.white),
  ),
  cardColor: Colors.grey[900],
  scaffoldBackgroundColor: Colors.black,
  dialogBackgroundColor: Colors.grey[900],
);
