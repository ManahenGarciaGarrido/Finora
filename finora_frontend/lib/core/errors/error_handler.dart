import 'dart:io';
import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Global error handler utility
class ErrorHandler {
  // Private constructor to prevent instantiation
  ErrorHandler._();

  /// Converts exceptions to user-friendly failure messages
  static Failure handleException(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is CacheException) {
      return CacheFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is NetworkException) {
      return NetworkFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is AuthenticationException) {
      return AuthenticationFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is AuthorizationException) {
      return AuthorizationFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is ValidationException) {
      return ValidationFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is NotFoundException) {
      return NotFoundFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is TimeoutException) {
      return TimeoutFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is DatabaseException) {
      return DatabaseFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is BiometricException) {
      return BiometricFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is PermissionException) {
      return PermissionFailure(
        message: error.message,
        code: error.code,
      );
    } else if (error is SocketException) {
      return const NetworkFailure(
        message: 'No internet connection. Please check your network settings.',
      );
    } else if (error is FormatException) {
      return const UnexpectedFailure(
        message: 'Invalid data format received.',
      );
    } else {
      return UnexpectedFailure(
        message: error?.toString() ?? 'An unexpected error occurred.',
      );
    }
  }

  /// Handles Dio-specific exceptions
  static Failure _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure(
          message: 'Connection timeout. Please try again.',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return const UnexpectedFailure(
          message: 'Request was cancelled.',
        );

      case DioExceptionType.connectionError:
        return const NetworkFailure(
          message: 'Connection error. Please check your internet connection.',
        );

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'SSL certificate verification failed.',
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return const NetworkFailure(
            message: 'No internet connection.',
          );
        }
        return UnexpectedFailure(
          message: error.message ?? 'An unexpected error occurred.',
        );
    }
  }

  /// Handles HTTP response errors
  static Failure _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = _extractErrorMessage(error.response?.data);

    switch (statusCode) {
      case 400:
        return ValidationFailure(
          message: message ?? 'Invalid request.',
          code: statusCode,
        );

      case 401:
        return AuthenticationFailure(
          message: message ?? 'Authentication failed. Please login again.',
          code: statusCode,
        );

      case 403:
        return AuthorizationFailure(
          message: message ?? 'You do not have permission to perform this action.',
          code: statusCode,
        );

      case 404:
        return NotFoundFailure(
          message: message ?? 'The requested resource was not found.',
          code: statusCode,
        );

      case 409:
        return ValidationFailure(
          message: message ?? 'Conflict with existing data.',
          code: statusCode,
        );

      case 422:
        return ValidationFailure(
          message: message ?? 'Validation failed.',
          code: statusCode,
        );

      case 429:
        return ServerFailure(
          message: message ?? 'Too many requests. Please try again later.',
          code: statusCode,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return ServerFailure(
          message: message ?? 'Server error. Please try again later.',
          code: statusCode,
        );

      default:
        return ServerFailure(
          message: message ?? 'An error occurred. Please try again.',
          code: statusCode,
        );
    }
  }

  /// Extracts error message from response data
  static String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      // Try common error message keys
      return data['message'] ??
             data['error'] ??
             data['detail'] ??
             data['msg'];
    }

    if (data is String) {
      return data;
    }

    return null;
  }

  /// Gets user-friendly error message from failure
  static String getErrorMessage(Failure failure) {
    return failure.message;
  }

  /// Determines if error is recoverable
  static bool isRecoverableError(Failure failure) {
    return failure is NetworkFailure ||
           failure is TimeoutFailure ||
           failure is ServerFailure;
  }

  /// Determines if error requires authentication
  static bool requiresAuthentication(Failure failure) {
    return failure is AuthenticationFailure;
  }
}
