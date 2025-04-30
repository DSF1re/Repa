import 'package:flutter/material.dart';
import 'package:prj/booking_screen.dart';
import 'package:prj/doctor_screen.dart';
import 'package:prj/home_screen.dart';
import 'package:prj/patient_screen.dart';
import 'package:prj/registration_screen.dart';
import 'package:prj/schedule_screen.dart';
import 'package:prj/unconfirmed_patients_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'auth_screen.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://gzioafwcbuaohbkhbkgw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6aW9hZndjYnVhb2hia2hia2d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE2MzExNTksImV4cCI6MjA1NzIwNzE1OX0.RB5J1dJd0L8qTuzNt0B-wEnbqg9ACTVlr8BTjIN1jZQ',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru', 'RU')],
      locale: const Locale('ru', 'RU'),
      theme: ThemeData(
        primaryColor: Colors.deepPurpleAccent,
        primarySwatch: Colors.deepPurple,
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
        cardTheme: const CardTheme(
          elevation: 4,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      ),
      routes: {
        '/': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/booking':
            (context) => BookingScreen(
              service:
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>,
            ),
        '/registration': (context) => const RegistrationScreen(),
        '/unconfirmedPatients': (context) => const UnconfirmedPatientsScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/doctors': (context) => const DoctorsScreen(),
        '/patients': (context) => const PatientsScreen(),
      },
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
    );
  }
}
