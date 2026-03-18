import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/consent.dart';
import '../repositories/gdpr_repository.dart';

/// Caso de uso para obtener los consentimientos del usuario
class GetUserConsentsUseCase implements UseCase<UserConsents, NoParams> {
  final GDPRRepository repository;

  GetUserConsentsUseCase(this.repository);

  @override
  Future<Either<Failure, UserConsents>> call(NoParams params) async {
    return await repository.getUserConsents();
  }
}

/// Caso de uso para actualizar los consentimientos del usuario
///
/// Permite al usuario dar o retirar consentimientos de forma explícita,
/// cumpliendo con el requisito de consentimiento del GDPR.
class UpdateConsentsUseCase
    implements UseCase<UserConsents, UpdateConsentsParams> {
  final GDPRRepository repository;

  UpdateConsentsUseCase(this.repository);

  @override
  Future<Either<Failure, UserConsents>> call(UpdateConsentsParams params) async {
    return await repository.updateConsents(params.consents);
  }
}

/// Parámetros para actualizar consentimientos
class UpdateConsentsParams extends Equatable {
  final Map<ConsentType, bool> consents;

  const UpdateConsentsParams({required this.consents});

  @override
  List<Object?> get props => [consents];
}

/// Caso de uso para retirar un consentimiento específico
class WithdrawConsentUseCase
    implements UseCase<UserConsents, WithdrawConsentParams> {
  final GDPRRepository repository;

  WithdrawConsentUseCase(this.repository);

  @override
  Future<Either<Failure, UserConsents>> call(
      WithdrawConsentParams params) async {
    return await repository.withdrawConsent(params.consentType);
  }
}

/// Parámetros para retirar un consentimiento
class WithdrawConsentParams extends Equatable {
  final ConsentType consentType;

  const WithdrawConsentParams({required this.consentType});

  @override
  List<Object?> get props => [consentType];
}

/// Caso de uso para obtener el historial de consentimientos
class GetConsentHistoryUseCase
    implements UseCase<List<ConsentHistoryEntry>, NoParams> {
  final GDPRRepository repository;

  GetConsentHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<ConsentHistoryEntry>>> call(
      NoParams params) async {
    return await repository.getConsentHistory();
  }
}
