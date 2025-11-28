import 'dart:async';

import 'package:clinic_app/models/user_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AppAuthBloc extends Bloc<AppAuthEvent, AppAuthState> {
  final AuthRepository _authRepository;
  late final StreamSubscription<supabase.AuthState> _authStateSubscription;

  AppAuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AppAuthState()) {
    on<AppAuthSignInRequested>(_onSignInRequested);
    on<AppAuthSignUpRequested>(_onSignUpRequested);
    on<AppAuthSignOutRequested>(_onSignOutRequested);
    on<AppAuthUserChanged>(_onUserChanged);

    _authStateSubscription = _authRepository.authStateChanges.listen((
      supabaseAuthState,
    ) {
      final user = supabaseAuthState.session?.user;
      if (user != null) {
        _loadUserData(user.id);
      } else {
        add(const AppAuthUserChanged(null));
      }
    });
  }

  Future<void> _onSignInRequested(
    AppAuthSignInRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final user = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );

      emit(
        state.copyWith(
          status: AppAuthStatus.authenticated,
          user: user,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AppAuthStatus.unauthenticated,
          isLoading: false,
          errorMessage: "Пользователь не найден или неверный пароль",
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    AppAuthSignUpRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      await _authRepository.signUp(
        email: event.email,
        password: event.password,
      );

      emit(
        state.copyWith(status: AppAuthStatus.unauthenticated, isLoading: false),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    AppAuthSignOutRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      emit(const AppAuthState(status: AppAuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  void _onUserChanged(AppAuthUserChanged event, Emitter<AppAuthState> emit) {
    if (event.user != null) {
      emit(
        state.copyWith(status: AppAuthStatus.authenticated, user: event.user),
      );
    } else {
      emit(const AppAuthState(status: AppAuthStatus.unauthenticated));
    }
  }

  Future<void> _loadUserData(String userId) async {
    try {
      final userData = await _authRepository.getUserData(userId);
      add(AppAuthUserChanged(userData));
    } catch (e) {
      add(const AppAuthUserChanged(null));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
