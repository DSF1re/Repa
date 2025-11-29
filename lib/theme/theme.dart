import 'package:flutter/material.dart';

final theme = ThemeData(
  primaryColor: Colors.deepPurpleAccent,
  primarySwatch: Colors.deepPurple,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    backgroundColor: Colors.deepPurple,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w600,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 24,
      color: Colors.white,
      fontWeight: FontWeight.w700,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      color: Colors.black,
      fontWeight: FontWeight.w300,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 16,
      color: Colors.black,
      fontWeight: FontWeight.w400,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 18,
      color: Colors.black,
      fontWeight: FontWeight.w500,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
    labelStyle: const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 14,
      color: Colors.black,
    ),
  ),
  cardTheme: const CardThemeData(
    elevation: 4,
    color: Colors.white,
    margin: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18.0)),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    ),
  ),
  drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
);
