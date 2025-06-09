// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppColors {
  static const Color lightBackground = Colors.white;
  static const Color lightText = Colors.black;

  static const Color darkBackground = Colors.black;
  static const Color darkText = Colors.white;

  static const Color notSelected = Color(0xFFBDBDBD);
  static const Color whiteTextColor = Colors.white;
  static const Color primary = Color(0xFF00B3B3);

}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    colorScheme: ColorScheme.light(
      background: AppColors.lightBackground,
      onPrimary: AppColors.whiteTextColor,
      onSecondary: AppColors.whiteTextColor,
      surface: AppColors.lightBackground,
      onSurface: AppColors.lightText,
      outline: Color.fromARGB(255, 230, 230, 230)
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Poppins',
        ),

    cardColor: AppColors.lightBackground,

    appBarTheme: AppBarTheme(
      foregroundColor: AppColors.whiteTextColor,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    colorScheme: ColorScheme.dark(
      background: AppColors.darkBackground,
      onPrimary: AppColors.whiteTextColor,
      onSecondary: AppColors.whiteTextColor,
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkText,
      outline: Color.fromARGB(255, 23, 23, 23),
    ),

    cardColor: AppColors.darkBackground,

    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Poppins',
    ),
    appBarTheme: AppBarTheme(
      foregroundColor: AppColors.darkText,
    ),
  );
}