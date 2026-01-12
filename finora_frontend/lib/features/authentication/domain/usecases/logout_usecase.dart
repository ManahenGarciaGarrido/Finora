import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Logout use case
/// Encapsulates the business logic for user logout
class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  /// Execute the logout use case
  /// Returns Either a Failure or void
  Future<Either<Failure, void>> call() async {
    return await repository.logout();
  }
}
