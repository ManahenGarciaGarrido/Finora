import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/core/network/secure_http_client.dart';
import 'package:finora_frontend/core/errors/exceptions.dart';

void main() {
  group('SecureHttpClient', () {
    test('should reject HTTP connections when not allowed', () {
      // Arrange
      final httpUri = Uri.parse('http://api.finora.com/endpoint');

      // Act & Assert
      expect(
        () => SecureHttpClient.validateConnection(httpUri),
        throwsA(isA<SecurityException>()),
      );
    });

    test('should accept HTTPS connections', () {
      // Arrange
      final httpsUri = Uri.parse('https://api.finora.com/endpoint');

      // Act & Assert
      expect(
        () => SecureHttpClient.validateConnection(httpsUri),
        returnsNormally,
      );
    });

    test('should reject non-HTTPS schemes', () {
      // Arrange
      final ftpUri = Uri.parse('ftp://api.finora.com/endpoint');

      // Act & Assert
      expect(
        () => SecureHttpClient.validateConnection(ftpUri),
        throwsA(isA<SecurityException>()),
      );
    });

    test('should create secure HTTP client', () {
      // Act
      final client = SecureHttpClient.create();

      // Assert
      expect(client, isNotNull);
      expect(client, isA<SecureHttpClient>());
    });
  });
}

