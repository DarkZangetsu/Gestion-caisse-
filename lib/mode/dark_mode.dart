import 'package:flutter/material.dart';

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  appBarTheme: const AppBarTheme(
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardColor: Colors.grey,
  colorScheme: ColorScheme.dark(
    primary: Colors.black,
    secondary: Colors.grey[800]!,
    onPrimary: Colors.white,
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.white,
      textStyle: const TextStyle(color: Colors.white),
    ),
  ),
);
