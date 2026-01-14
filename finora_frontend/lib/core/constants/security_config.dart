/// Security configuration constants for secure communications
class SecurityConfig {
  // Private constructor to prevent instantiation
  SecurityConfig._();

  /// Minimum TLS version allowed (TLS 1.3)
  static const String minTlsVersion = 'TLSv1.3';

  /// Allowed TLS protocols
  static const List<String> allowedProtocols = ['TLSv1.3'];

  /// Certificate pinning enabled
  static const bool certificatePinningEnabled = true;

  /// Allow HTTP connections (should be false in production)
  static const bool allowHttpConnections = false;

  /// Certificate fingerprints (SHA-256) for pinning
  /// TODO: Replace with actual production certificate fingerprints
  static const Map<String, List<String>> certificatePins = {
    'api.finora.com': [
      // Production certificate SHA-256 fingerprints
      // Example: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='
      // Add your actual certificate fingerprints here
    ],
  };

  /// Bad certificate error message
  static const String badCertificateMessage =
      'SSL certificate verification failed. Connection rejected for security reasons.';

  /// HTTP connection error message
  static const String httpConnectionMessage =
      'HTTP connections are not allowed. Use HTTPS instead.';

  /// TLS version error message
  static const String tlsVersionMessage =
      'TLS version not supported. Minimum required: TLS 1.3';
}
