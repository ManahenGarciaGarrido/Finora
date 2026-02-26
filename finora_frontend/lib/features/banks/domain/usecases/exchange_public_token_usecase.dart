import '../repositories/bank_repository.dart';

/// RF-10: Intercambia el public_token de Plaid Link por un access_token.
///
/// El WebView de Android no puede hacer la llamada HTTP directamente
/// (restricciones de contexto mixto). Flutter captura el token vía canal
/// JavaScript y lo intercambia usando el cliente HTTP de Dart.
class ExchangePublicTokenUseCase {
  final BankRepository repository;
  ExchangePublicTokenUseCase(this.repository);

  Future<void> call({
    required String connectionId,
    required String publicToken,
    required String institutionName,
  }) {
    return repository.exchangePublicToken(
      connectionId: connectionId,
      publicToken: publicToken,
      institutionName: institutionName,
    );
  }
}
