import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/security_config.dart';
import '../errors/exceptions.dart';
import 'secure_http_client.dart';

/// TLS and security validator for HTTP connections
class TlsValidator {
  TlsValidator._();

  /// Validates request security before sending
  static void validateRequest(RequestOptions options) {
    final uri = options.uri;

    // Allow HTTP for local development (localhost, 10.0.2.2 for Android emulator)
    final isLocalDevelopment =
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '192.168.100.88' ||
        uri.host == '10.0.2.2';

    if (isLocalDevelopment) {
      // Skip TLS validation for local development
      return;
    }

    // Validate connection security for production
    SecureHttpClient.validateConnection(uri);

    // Ensure proper scheme for production
    if (uri.scheme != 'https') {
      throw SecurityException(
        message:
            '${SecurityConfig.httpConnectionMessage} (URI: ${uri.toString()})',
      );
    }
  }

  /// Creates a security interceptor for Dio
  static Interceptor createSecurityInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        try {
          // Validate request before sending
          validateRequest(options);
          handler.next(options);
        } catch (e) {
          handler.reject(
            DioException(
              requestOptions: options,
              error: e,
              type: DioExceptionType.badResponse,
            ),
          );
        }
      },
      onError: (error, handler) {
        // Handle certificate errors
        if (error.type == DioExceptionType.badCertificate) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              error: SecurityConfig.badCertificateMessage,
              type: DioExceptionType.badCertificate,
            ),
          );
        } else {
          handler.next(error);
        }
      },
    );
  }

  /// Checks if the platform supports TLS 1.3
  static Future<TlsSupport> checkTlsSupport() async {
    try {
      // Check platform version
      if (Platform.isAndroid) {
        // Android 10 (API 29) and above support TLS 1.3
        return TlsSupport(
          isSupported: true,
          version: 'TLS 1.3',
          details: 'Android supports TLS 1.3 from API 29+',
        );
      } else if (Platform.isIOS) {
        // iOS 13+ supports TLS 1.3
        return TlsSupport(
          isSupported: true,
          version: 'TLS 1.3',
          details: 'iOS supports TLS 1.3 from iOS 13.0+',
        );
      } else if (Platform.isMacOS) {
        // macOS 10.15+ supports TLS 1.3
        return TlsSupport(
          isSupported: true,
          version: 'TLS 1.3',
          details: 'macOS supports TLS 1.3 from 10.15+',
        );
      }

      return TlsSupport(
        isSupported: false,
        version: 'Unknown',
        details: 'Platform TLS support could not be determined',
      );
    } catch (e) {
      return TlsSupport(
        isSupported: false,
        version: 'Unknown',
        details: 'Error checking TLS support: $e',
      );
    }
  }
}

/// TLS support information
class TlsSupport {
  final bool isSupported;
  final String version;
  final String details;

  TlsSupport({
    required this.isSupported,
    required this.version,
    required this.details,
  });

  @override
  String toString() {
    return 'TLS Support: $version (Supported: $isSupported) - $details';
  }
}
