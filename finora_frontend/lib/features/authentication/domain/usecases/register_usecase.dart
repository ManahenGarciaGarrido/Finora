import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Register use case
/// Encapsulates the business logic for user registration
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Execute the register use case
  /// Returns Either a Failure or a User
  Future<Either<Failure, User>> call(RegisterParams params) async {
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

    if (params.name.isEmpty) {
      return const Left(
        ValidationFailure(message: 'Name cannot be empty'),
      );
    }

    // Email format validation
    if (!_isValidEmail(params.email)) {
      return const Left(
        ValidationFailure(message: 'Invalid email format'),
      );
    }

    // Password strength validation
    if (params.password.length < AppConstants.minPasswordLength) {
      return Left(
        ValidationFailure(
          message: 'Password must be at least ${AppConstants.minPasswordLength} characters',
        ),
      );
    }

    if (!_isStrongPassword(params.password)) {
      return const Left(
        ValidationFailure(
          message: 'Password must contain uppercase, lowercase, number and special character',
        ),
      );
    }

    // Name validation
    if (params.name.length < AppConstants.minUsernameLength) {
      return Left(
        ValidationFailure(
          message: 'Name must be at least ${AppConstants.minUsernameLength} characters',
        ),
      );
    }

    // Call repository
    return await repository.register(
      email: params.email,
      password: params.password,
      name: params.name,
      phoneNumber: params.phoneNumber,
      consents: params.consents,
    );
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool _isStrongPassword(String password) {
    // At least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    // At least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    // At least one digit
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    // At least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }
}

/// Register parameters
class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final String? phoneNumber;
  final Map<String, bool>? consents;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    this.phoneNumber,
    this.consents,
  });

  @override
  List<Object?> get props => [email, password, name, phoneNumber, consents];
}
