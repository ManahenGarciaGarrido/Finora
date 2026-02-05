import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

/// Base class for all authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state - user is logged in
class Authenticated extends AuthState {
  final User user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state - user is not logged in
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Error state
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Registration success state
class RegistrationSuccess extends AuthState {
  final User user;

  const RegistrationSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Logout success state
class LogoutSuccess extends AuthState {
  const LogoutSuccess();
}

/// Email resent success state
class EmailResent extends AuthState {
  final String message;

  const EmailResent({this.message = 'Correo de verificación enviado exitosamente'});

  @override
  List<Object?> get props => [message];
}

/// Password reset email sent state
class PasswordResetEmailSent extends AuthState {
  final String message;

  const PasswordResetEmailSent({
    this.message = 'Se ha enviado un enlace de recuperación a tu correo',
  });

  @override
  List<Object?> get props => [message];
}

/// Password reset success state
class PasswordResetSuccess extends AuthState {
  final String message;

  const PasswordResetSuccess({
    this.message = 'Contraseña restablecida exitosamente',
  });

  @override
  List<Object?> get props => [message];
}
