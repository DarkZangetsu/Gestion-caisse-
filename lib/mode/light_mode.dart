import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    iconTheme: IconThemeData(color: Colors.black),
  ),
  colorScheme: ColorScheme.light(
    surface: Colors.grey[200]!,
    primary: Colors.grey[300]!,
    secondary: Colors.grey[400]!,
    onPrimary: Colors.white,
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.black,
      textStyle: const TextStyle(color: Colors.black),
    ),
  ),
);
