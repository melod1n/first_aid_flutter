import 'package:flutter/material.dart';

class Themes {
  static final light = ThemeData.light(useMaterial3: true).copyWith(
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.deepPurple,
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ThemeData.light(useMaterial3: true).colorScheme.copyWith(
          background: Colors.white,
          onBackground: Colors.black,
          primary: Colors.deepPurple,
          onPrimary: Colors.white));
  static final dark = ThemeData.dark(useMaterial3: true).copyWith(
      buttonTheme: const ButtonThemeData(
        buttonColor: Colors.deepPurple,
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: ThemeData.dark(useMaterial3: true).colorScheme.copyWith(
          background: Colors.black,
          onBackground: Colors.white,
          primary: Colors.deepPurple,
          onPrimary: Colors.white));
}
