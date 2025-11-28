part of 'auth_bloc.dart';

enum AppAuthStatus { initial, loading, authenticated, unauthenticated }

class AppAuthState extends Equatable {
  final AppAuthStatus status;
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const AppAuthState({
    this.status = AppAuthStatus.initial,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AppAuthState copyWith({
    AppAuthStatus? status,
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, isLoading, errorMessage];
}
