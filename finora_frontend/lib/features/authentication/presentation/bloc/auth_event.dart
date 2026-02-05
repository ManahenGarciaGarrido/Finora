import 'package:equatable/equatable.dart';

/// Base class for all authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to trigger login
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Event to trigger registration
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? phoneNumber;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [email, password, name, phoneNumber];
}

/// Event to trigger logout
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event to check authentication status
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

/// Event to clear error state
class ClearAuthError extends AuthEvent {
  const ClearAuthError();
}

/// Event to resend email verification
class ResendVerificationRequested extends AuthEvent {
  final String email;

  const ResendVerificationRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
