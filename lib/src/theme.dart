import 'package:flutter/material.dart';

const brandBlue = Color(0xFF087BEE);
const ink = Color(0xFF172033);
const canvas = Color(0xFFF6F8FC);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
          seedColor: brandBlue, primary: brandBlue, surface: Colors.white),
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F5F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE7EBF1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: brandBlue, width: 1.5)),
      ),
    );

ThemeData buildDarkTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2AABEE),
          primary: const Color(0xFF2AABEE),
          brightness: Brightness.dark,
          surface: const Color(0xFF17212B)),
      scaffoldBackgroundColor: const Color(0xFF0E1621),
      fontFamily: 'Arial',
      appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF17212B),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent),
      cardTheme: const CardTheme(color: Color(0xFF17212B)),
      navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF17212B),
          indicatorColor: Color(0xFF243B4D)),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF242F3D),
        hintStyle: const TextStyle(color: Color(0xFF708499)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2B3A49))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2AABEE), width: 1.5)),
      ),
    );
