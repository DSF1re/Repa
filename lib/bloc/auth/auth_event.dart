part of 'auth_bloc.dart';

abstract class AppAuthEvent extends Equatable {
  const AppAuthEvent();

  @override
  List<Object?> get props => [];
}

class AppAuthSignInRequested extends AppAuthEvent {
  final String email;
  final String password;

  const AppAuthSignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AppAuthSignUpRequested extends AppAuthEvent {
  final String email;
  final String password;
  final UserModel userData;

  const AppAuthSignUpRequested({
    required this.email,
    required this.password,
    required this.userData,
  });

  @override
  List<Object> get props => [email, password, userData];
}

class AppAuthSignOutRequested extends AppAuthEvent {}

class AppAuthUserChanged extends AppAuthEvent {
  final UserModel? user;

  const AppAuthUserChanged(this.user);

  @override
  List<Object?> get props => [user];
}
