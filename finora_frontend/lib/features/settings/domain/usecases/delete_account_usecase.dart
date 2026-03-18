import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_data_export.dart';
import '../repositories/gdpr_repository.dart';

/// Caso de uso para eliminar completamente la cuenta del usuario
///
/// Implementa el derecho al olvido según el Artículo 17 del GDPR.
/// Elimina todos los datos personales del usuario de forma permanente.
class DeleteAccountUseCase
    implements UseCase<AccountDeletionReceipt, DeleteAccountParams> {
  final GDPRRepository repository;

  DeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, AccountDeletionReceipt>> call(
      DeleteAccountParams params) async {
    return await repository.deleteAccount(reason: params.reason);
  }
}

/// Parámetros para la eliminación de cuenta
class DeleteAccountParams extends Equatable {
  /// Razón opcional por la que el usuario desea eliminar su cuenta
  final String? reason;

  const DeleteAccountParams({this.reason});

  @override
  List<Object?> get props => [reason];
}
