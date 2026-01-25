import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/privacy_policy.dart';
import '../repositories/gdpr_repository.dart';

/// Caso de uso para obtener la política de privacidad
class GetPrivacyPolicyUseCase implements UseCase<PrivacyPolicy, NoParams> {
  final GDPRRepository repository;

  GetPrivacyPolicyUseCase(this.repository);

  @override
  Future<Either<Failure, PrivacyPolicy>> call(NoParams params) async {
    return await repository.getPrivacyPolicy();
  }
}

/// Caso de uso para obtener información sobre el procesamiento de datos
class GetDataProcessingInfoUseCase
    implements UseCase<DataProcessingInfo, NoParams> {
  final GDPRRepository repository;

  GetDataProcessingInfoUseCase(this.repository);

  @override
  Future<Either<Failure, DataProcessingInfo>> call(NoParams params) async {
    return await repository.getDataProcessingInfo();
  }
}

/// Caso de uso para obtener información del DPO (Data Protection Officer)
class GetDPOInfoUseCase implements UseCase<DPOInfo, NoParams> {
  final GDPRRepository repository;

  GetDPOInfoUseCase(this.repository);

  @override
  Future<Either<Failure, DPOInfo>> call(NoParams params) async {
    return await repository.getDPOInfo();
  }
}
