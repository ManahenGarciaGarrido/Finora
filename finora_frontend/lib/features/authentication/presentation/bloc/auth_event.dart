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

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to trigger registration
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? phoneNumber;
  final Map<String, bool>? consents;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    this.phoneNumber,
    this.consents,
  });

  @override
  List<Object?> get props => [email, password, name, phoneNumber, consents];
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

/// Event to request password reset
class ForgotPasswordRequested extends AuthEvent {
  final String email;

  const ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Event to reset password with token
class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const ResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [token, newPassword];
}

/// RF-03: Event to trigger social login
class BiometricLoginRequested extends AuthEvent {
  const BiometricLoginRequested();
}

/// RF-03: Event to check if biometric auth is available and enabled
class CheckBiometricAvailability extends AuthEvent {
  const CheckBiometricAvailability();
}

/// RF-09: Update local user profile name after successful backend update
class UpdateProfileName extends AuthEvent {
  final String name;
  const UpdateProfileName({required this.name});

  @override
  List<Object?> get props => [name];
}
