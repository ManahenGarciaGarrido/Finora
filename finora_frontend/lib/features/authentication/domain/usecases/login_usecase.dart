import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Login use case
/// Encapsulates the business logic for user login
/// Follows the single responsibility principle
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  /// Execute the login use case
  /// Returns Either a Failure or a User
  Future<Either<Failure, User>> call(LoginParams params) async {
    // Business logic validation
    if (params.email.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Email cannot be empty'),
      );
    }

    if (params.password.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Password cannot be empty'),
      );
    }

    // Email format validation
    if (!_isValidEmail(params.email)) {
      return const Left(
        ValidationFailure(message: 'Invalid email format'),
      );
    }

    // Call repository
    return await repository.login(
      email: params.email,
      password: params.password,
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

/// Login parameters
class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}
