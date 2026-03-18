
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/consent.dart';
import '../models/consent_model.dart';
import '../models/privacy_policy_model.dart';
import '../models/user_data_export_model.dart';

/// Datasource remoto para operaciones GDPR
abstract class GDPRRemoteDataSource {
  /// Obtiene la política de privacidad
  Future<PrivacyPolicyModel> getPrivacyPolicy();

  /// Obtiene información del procesamiento de datos
  Future<DataProcessingInfoModel> getDataProcessingInfo();

  /// Obtiene los tipos de consentimiento disponibles
  Future<Map<String, dynamic>> getConsentTypes();

  /// Obtiene los consentimientos del usuario
  Future<UserConsentsModel> getUserConsents();

  /// Actualiza los consentimientos del usuario
  Future<UserConsentsModel> updateConsents(Map<ConsentType, bool> consents);

  /// Retira un consentimiento específico
  Future<UserConsentsModel> withdrawConsent(ConsentType consentType);

  /// Obtiene el historial de consentimientos
  Future<List<ConsentHistoryEntryModel>> getConsentHistory();

  /// Exporta todos los datos del usuario (portabilidad)
  Future<UserDataExportModel> exportUserData();

  /// Elimina la cuenta del usuario (derecho al olvido)
  Future<AccountDeletionReceiptModel> deleteAccount(String? reason);
}

/// Implementación del datasource remoto GDPR
class GDPRRemoteDataSourceImpl implements GDPRRemoteDataSource {
  final ApiClient _apiClient;

  GDPRRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<PrivacyPolicyModel> getPrivacyPolicy() async {
    final response = await _apiClient.get(ApiEndpoints.gdprPrivacyPolicy);
    final data = response.data as Map<String, dynamic>;
    return PrivacyPolicyModel.fromJson(
        data['privacyPolicy'] as Map<String, dynamic>);
  }

  @override
  Future<DataProcessingInfoModel> getDataProcessingInfo() async {
    final response = await _apiClient.get(ApiEndpoints.gdprDataProcessing);
    final data = response.data as Map<String, dynamic>;
    return DataProcessingInfoModel.fromJson(
        data['dataProcessing'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getConsentTypes() async {
    final response = await _apiClient.get(ApiEndpoints.gdprConsents);
    final data = response.data as Map<String, dynamic>;
    return data['consentTypes'] as Map<String, dynamic>;
  }

  @override
  Future<UserConsentsModel> getUserConsents() async {
    final response = await _apiClient.get(ApiEndpoints.gdprUserConsents);
    final data = response.data as Map<String, dynamic>;
    return UserConsentsModel.fromJson({
      'userId': data['userId'],
      'consents': data['consents']['consents'],
      'lastUpdated': data['lastUpdated'],
      'history': data['consents']['history'] ?? [],
    });
  }

  @override
  Future<UserConsentsModel> updateConsents(
      Map<ConsentType, bool> consents) async {
    final consentsJson = <String, bool>{};
    consents.forEach((key, value) {
      consentsJson[key.key] = value;
    });

    final response = await _apiClient.post(
      ApiEndpoints.gdprConsents,
      data: {'consents': consentsJson},
    );

    final data = response.data as Map<String, dynamic>;
    return UserConsentsModel.fromJson(
        data['consents'] as Map<String, dynamic>);
  }

  @override
  Future<UserConsentsModel> withdrawConsent(ConsentType consentType) async {
    final response = await _apiClient.delete(
      ApiEndpoints.gdprWithdrawConsent(consentType.key),
    );

    final data = response.data as Map<String, dynamic>;
    return UserConsentsModel.fromJson(
        data['consents'] as Map<String, dynamic>);
  }

  @override
  Future<List<ConsentHistoryEntryModel>> getConsentHistory() async {
    final response = await _apiClient.get(ApiEndpoints.gdprConsentHistory);
    final data = response.data as Map<String, dynamic>;
    final history = data['history'] as List<dynamic>;
    return history
        .map((e) =>
            ConsentHistoryEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserDataExportModel> exportUserData() async {
    final response = await _apiClient.get(ApiEndpoints.gdprExport);
    final data = response.data as Map<String, dynamic>;
    return UserDataExportModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  @override
  Future<AccountDeletionReceiptModel> deleteAccount(String? reason) async {
    final response = await _apiClient.delete(
      ApiEndpoints.gdprDeleteAccount,
      data: {
        'confirmDeletion': 'DELETE_MY_ACCOUNT',
        if (reason != null) 'reason': reason,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return AccountDeletionReceiptModel.fromJson(
        data['deletionReceipt'] as Map<String, dynamic>);
  }
}
