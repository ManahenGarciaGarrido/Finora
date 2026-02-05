import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Forgot password use case
/// Encapsulates the business logic for password recovery request
/// Follows the single responsibility principle
class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  /// Execute the forgot password use case
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> call(ForgotPasswordParams params) async {
    // Business logic validation
    if (params.email.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Email no puede estar vacío'),
      );
    }

    // Email format validation
    if (!_isValidEmail(params.email)) {
      return const Left(
        ValidationFailure(message: 'Formato de email inválido'),
      );
    }

    // Call repository
    return await repository.forgotPassword(
      email: params.email,
    );
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

/// Forgot password parameters
class ForgotPasswordParams extends Equatable {
  final String email;

  const ForgotPasswordParams({
    required this.email,
  });

  @override
  List<Object?> get props => [email];
}
