import 'package:clinic_app/bloc/doctors/doctors_bloc.dart';
import 'package:clinic_app/bloc/patients/patients_bloc.dart';
import 'package:clinic_app/bloc/schedule/schedule_bloc.dart';
import 'package:clinic_app/bloc/unconfirmed_patients/unconfirmed_patients_bloc.dart';
import 'package:clinic_app/bloc/records/records_bloc.dart';
import 'package:clinic_app/repositories/doctors_repository.dart';
import 'package:clinic_app/repositories/records_repository.dart';
import 'package:clinic_app/repositories/schedule_repository.dart';
import 'package:clinic_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bloc/auth/auth_bloc.dart';
import 'repositories/auth_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/service_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://gzioafwcbuaohbkhbkgw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd6aW9hZndjYnVhb2hia2hia2d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE2MzExNTksImV4cCI6MjA1NzIwNzE1OX0.RB5J1dJd0L8qTuzNt0B-wEnbqg9ACTVlr8BTjIN1jZQ',
  );

  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        BlocProvider<DoctorsBloc>(
          create: (context) => DoctorsBloc(
            doctorsRepository: DoctorsRepository(),
            userRepository: UserRepository(supabaseClient: supabase),
          ),
        ),
        BlocProvider<PatientsBloc>(
          create: (context) => PatientsBloc(
            userRepository: UserRepository(supabaseClient: supabase),
          ),
        ),
        BlocProvider<AppAuthBloc>(
          create: (context) => AppAuthBloc(authRepository: AuthRepository()),
        ),
        BlocProvider<ScheduleBloc>(
          create: (context) =>
              ScheduleBloc(scheduleRepository: ScheduleRepository()),
        ),
        BlocProvider<UnconfirmedPatientsBloc>(
          create: (context) => UnconfirmedPatientsBloc(
            userRepository: UserRepository(supabaseClient: supabase),
          ),
        ),
        BlocProvider<RecordsBloc>(
          create: (context) => RecordsBloc(
            recordsRepository: RecordsRepository(supabaseClient: supabase),
          ),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<UserRepository>(
          create: (context) => UserRepository(supabaseClient: supabase),
        ),
        RepositoryProvider<ServiceRepository>(
          create: (context) => ServiceRepository(supabaseClient: supabase),
        ),
        RepositoryProvider<RecordsRepository>(
          create: (context) => RecordsRepository(supabaseClient: supabase),
        ),
      ],
      child: BlocProvider<AppAuthBloc>(
        create: (context) => AppAuthBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        ),
        child: MaterialApp(
          title: 'Medical App',
          theme: theme,
          home: const AppWrapper(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppAuthBloc, AppAuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AppAuthStatus.authenticated:
            return const HomeScreen();
          case AppAuthStatus.unauthenticated:
            return const AuthScreen();
          case AppAuthStatus.initial:
          case AppAuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
        }
      },
    );
  }
}
