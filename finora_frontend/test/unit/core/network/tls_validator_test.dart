import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/core/network/tls_validator.dart';
import 'package:finora_frontend/core/errors/exceptions.dart';
import 'package:dio/dio.dart';

void main() {
  group('TlsValidator', () {
    test('should validate HTTPS request successfully', () {
      // Arrange
      final options = RequestOptions(
        path: '/endpoint',
        baseUrl: 'https://api.finora.com',
      );

      // Act & Assert
      expect(
        () => TlsValidator.validateRequest(options),
        returnsNormally,
      );
    });

    test('should reject HTTP request', () {
      // Arrange
      final options = RequestOptions(
        path: '/endpoint',
        baseUrl: 'http://api.finora.com',
      );

      // Act & Assert
      expect(
        () => TlsValidator.validateRequest(options),
        throwsA(isA<SecurityException>()),
      );
    });

    test('should check TLS support', () async {
      // Act
      final support = await TlsValidator.checkTlsSupport();

      // Assert
      expect(support, isNotNull);
      expect(support.version, isNotEmpty);
      expect(support.details, isNotEmpty);
    });

    test('should create security interceptor', () {
      // Act
      final interceptor = TlsValidator.createSecurityInterceptor();

      // Assert
      expect(interceptor, isNotNull);
      expect(interceptor, isA<Interceptor>());
    });
  });
}

