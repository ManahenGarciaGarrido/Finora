import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/consent.dart';
import '../entities/privacy_policy.dart';
import '../entities/user_data_export.dart';

/// Repositorio abstracto para operaciones GDPR
///
/// Este repositorio define todas las operaciones necesarias para
/// cumplir con el GDPR (Reglamento General de Protección de Datos):
/// - Gestión de consentimientos
/// - Derecho de acceso (exportación de datos)
/// - Derecho al olvido (eliminación de cuenta)
/// - Información sobre tratamiento de datos
abstract class GDPRRepository {
  /// Obtiene la política de privacidad
  Future<Either<Failure, PrivacyPolicy>> getPrivacyPolicy();

  /// Obtiene información sobre el procesamiento de datos
  Future<Either<Failure, DataProcessingInfo>> getDataProcessingInfo();

  /// Obtiene los consentimientos actuales del usuario
  Future<Either<Failure, UserConsents>> getUserConsents();

  /// Actualiza los consentimientos del usuario
  Future<Either<Failure, UserConsents>> updateConsents(
    Map<ConsentType, bool> consents,
  );

  /// Retira un consentimiento específico
  Future<Either<Failure, UserConsents>> withdrawConsent(ConsentType consentType);

  /// Obtiene el historial de cambios de consentimiento
  Future<Either<Failure, List<ConsentHistoryEntry>>> getConsentHistory();

  /// Exporta todos los datos del usuario (derecho de portabilidad)
  /// Artículo 20 GDPR
  Future<Either<Failure, UserDataExport>> exportUserData();

  /// Elimina completamente la cuenta del usuario (derecho al olvido)
  /// Artículo 17 GDPR
  Future<Either<Failure, AccountDeletionReceipt>> deleteAccount({String? reason});
}
