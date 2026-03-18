/// Base exception class
/// Exceptions are used in the data layer and converted to Failures in repositories
class AppException implements Exception {
  final String message;
  final int? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'CacheException: $message (code: $code)';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'NetworkException: $message (code: $code)';
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'AuthenticationException: $message (code: $code)';
}

/// Authorization-related exceptions
class AuthorizationException extends AppException {
  const AuthorizationException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'AuthorizationException: $message (code: $code)';
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ValidationException: $message (code: $code)';
}

/// Not found exceptions
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'NotFoundException: $message (code: $code)';
}

/// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'TimeoutException: $message (code: $code)';
}

/// Unknown/Unexpected exceptions
class UnexpectedException extends AppException {
  const UnexpectedException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'UnexpectedException: $message (code: $code)';
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'DatabaseException: $message (code: $code)';
}

/// Biometric authentication exceptions
class BiometricException extends AppException {
  const BiometricException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'BiometricException: $message (code: $code)';
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'PermissionException: $message (code: $code)';
}

/// Parse/Serialization exceptions
class ParseException extends AppException {
  const ParseException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'ParseException: $message (code: $code)';
}

/// Security-related exceptions (TLS, certificate pinning, HTTPS enforcement)
class SecurityException extends AppException {
  const SecurityException({
    required super.message,
    super.code,
    super.details,
  });

  @override
  String toString() => 'SecurityException: $message (code: $code)';
}
