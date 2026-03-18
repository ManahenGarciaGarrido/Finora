import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Reset password use case
/// Encapsulates the business logic for resetting password with token
/// Follows the single responsibility principle
class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  /// Execute the reset password use case
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    // Business logic validation
    if (params.token.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Token no puede estar vacío'),
      );
    }

    if (params.newPassword.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Contraseña no puede estar vacía'),
      );
    }

    // Password strength validation
    if (params.newPassword.length < 8) {
      return const Left(
        ValidationFailure(
          message: 'La contraseña debe tener al menos 8 caracteres',
        ),
      );
    }

    if (!_isStrongPassword(params.newPassword)) {
      return const Left(
        ValidationFailure(
          message:
              'La contraseña debe contener mayúsculas, números y caracteres especiales',
        ),
      );
    }

    // Call repository
    return await repository.resetPassword(
      token: params.token,
      newPassword: params.newPassword,
    );
  }

  /// Validate password strength
  bool _isStrongPassword(String password) {
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(
      RegExp(
        r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;'
        r"']",
      ),
    );

    return hasUpperCase && hasNumber && hasSpecialChar;
  }
}

/// Reset password parameters
class ResetPasswordParams extends Equatable {
  final String token;
  final String newPassword;

  const ResetPasswordParams({required this.token, required this.newPassword});

  @override
  List<Object?> get props => [token, newPassword];
}
