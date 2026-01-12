import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Authentication repository interface
/// This is part of the domain layer and defines the contract
/// The actual implementation is in the data layer
/// This follows the dependency inversion principle
abstract class AuthRepository {
  /// Login with email and password
  /// Returns Either a Failure or a User
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Register a new user
  /// Returns Either a Failure or a User
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  });

  /// Logout current user
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> logout();

  /// Get current authenticated user
  /// Returns Either a Failure or a User
  Future<Either<Failure, User>> getCurrentUser();

  /// Check if user is logged in
  /// Returns true if user is authenticated
  Future<bool> isLoggedIn();

  /// Refresh authentication token
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> refreshToken();

  /// Request password reset
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> forgotPassword({
    required String email,
  });

  /// Reset password with token
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Enable two-factor authentication
  /// Returns Either a Failure or String (QR code or secret)
  Future<Either<Failure, String>> enable2FA();

  /// Verify two-factor authentication code
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> verify2FA({
    required String code,
  });

  /// Disable two-factor authentication
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> disable2FA();
}
