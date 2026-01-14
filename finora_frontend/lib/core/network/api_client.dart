import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../constants/api_endpoints.dart';
import '../errors/exceptions.dart';
import 'secure_http_client.dart';
import 'tls_validator.dart';

/// HTTP client for API communication with secure TLS 1.3 enforcement
/// Singleton pattern ensures single instance throughout the app
class ApiClient {
  late final Dio _dio;
  String? _accessToken;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Configure secure HTTP client with TLS 1.3
    _dio.httpClientAdapter = SecureHttpClient.create();

    _setupInterceptors();
  }

  /// Setup request/response interceptors
  void _setupInterceptors() {
    // Add security interceptor first (validates HTTPS and TLS)
    _dio.interceptors.add(TlsValidator.createSecurityInterceptor());

    // Add authentication interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add authentication token if available
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  /// Set authentication token
  void setToken(String token) {
    _accessToken = token;
  }

  /// Clear authentication token
  void clearToken() {
    _accessToken = null;
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnexpectedException(message: e.toString());
    }
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnexpectedException(message: e.toString());
    }
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnexpectedException(message: e.toString());
    }
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnexpectedException(message: e.toString());
    }
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw UnexpectedException(message: e.toString());
    }
  }

  /// Handle Dio errors and convert to custom exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'Connection timeout',
          details: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response?.data);

        switch (statusCode) {
          case 401:
            return AuthenticationException(
              message: message ?? 'Authentication failed',
              code: statusCode,
              details: error,
            );
          case 403:
            return AuthorizationException(
              message: message ?? 'Access denied',
              code: statusCode,
              details: error,
            );
          case 404:
            return NotFoundException(
              message: message ?? 'Resource not found',
              code: statusCode,
              details: error,
            );
          case 422:
            return ValidationException(
              message: message ?? 'Validation failed',
              code: statusCode,
              details: error,
            );
          case 500:
          case 502:
          case 503:
            return ServerException(
              message: message ?? 'Server error',
              code: statusCode,
              details: error,
            );
          default:
            return ServerException(
              message: message ?? 'Request failed',
              code: statusCode,
              details: error,
            );
        }

      case DioExceptionType.cancel:
        return const UnexpectedException(
          message: 'Request was cancelled',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'Connection error',
        );

      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'SSL certificate error',
        );

      case DioExceptionType.unknown:
        return NetworkException(
          message: error.message ?? 'Unknown error',
          details: error,
        );
    }
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
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
}
