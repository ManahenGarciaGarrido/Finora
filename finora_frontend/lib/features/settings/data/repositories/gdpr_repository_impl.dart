import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/consent.dart';
import '../../domain/entities/privacy_policy.dart';
import '../../domain/entities/user_data_export.dart';
import '../../domain/repositories/gdpr_repository.dart';
import '../datasources/gdpr_remote_datasource.dart';

/// Implementación del repositorio GDPR
class GDPRRepositoryImpl implements GDPRRepository {
  final GDPRRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  GDPRRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, PrivacyPolicy>> getPrivacyPolicy() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPrivacyPolicy();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, DataProcessingInfo>> getDataProcessingInfo() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getDataProcessingInfo();
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserConsents>> getUserConsents() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getUserConsents();
        return Right(result);
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserConsents>> updateConsents(
    Map<ConsentType, bool> consents,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateConsents(consents);
        return Right(result);
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserConsents>> withdrawConsent(
    ConsentType consentType,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.withdrawConsent(consentType);
        return Right(result);
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<ConsentHistoryEntry>>> getConsentHistory() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getConsentHistory();
        return Right(result);
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserDataExport>> exportUserData() async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.exportUserData();
        return Right(result);
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AccountDeletionReceipt>> deleteAccount({
    String? reason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteAccount(reason);
        return Right(result);
      } on AuthenticationException catch (e) {
        return Left(AuthenticationFailure(message: e.message));
      } on ValidationException catch (e) {
        return Left(ValidationFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } on NetworkException catch (e) {
        return Left(NetworkFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
