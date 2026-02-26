import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor de reintentos con backoff exponencial y jitter (RNF-16).
///
/// Reintenta peticiones fallidas con delay creciente:
///   Intento 1 → inmediato
///   Intento 2 → ~500ms
///   Intento 3 → ~1000ms
///   Intento 4 → ~2000ms (máx configurado en maxDelayMs)
///
/// Solo reintenta en errores recuperables:
///   - Timeout de conexión/envío/recepción
///   - Error de conexión (sin internet)
///   - Errores HTTP 5xx del servidor
///
/// NO reintenta en:
///   - Errores 4xx (error del cliente → sin sentido reintentar)
///   - 401/403 (autenticación/autorización)
///   - Cancelaciones
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final int baseDelayMs;
  final int maxDelayMs;

  static const _retryCountKey = '_retry_count';

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelayMs = 500,
    this.maxDelayMs = 30000,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final attempt = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (attempt >= maxRetries) {
      debugPrint(
        '[RetryInterceptor] Max reintentos ($maxRetries) alcanzados para ${err.requestOptions.path}',
      );
      return handler.next(err);
    }

    final delay = _computeDelay(attempt);
    debugPrint(
      '[RetryInterceptor] Error recuperable en ${err.requestOptions.path}. '
      'Reintento ${attempt + 1}/$maxRetries en ${delay}ms. '
      'Error: ${err.type.name}',
    );

    await Future.delayed(Duration(milliseconds: delay));

    final options = err.requestOptions.copyWith(
      extra: {...err.requestOptions.extra, _retryCountKey: attempt + 1},
    );

    try {
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }

  bool _shouldRetry(DioException err) {
    switch (err.type) {
      // Timeout y errores de red → reintentar
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      // Respuestas HTTP → solo reintentar en 5xx
      case DioExceptionType.badResponse:
        final status = err.response?.statusCode ?? 0;
        // 5xx: error del servidor (probablemente transitorio)
        if (status >= 500 && status < 600) return true;
        // 429: rate limit — reintentar con delay mayor
        if (status == 429) return true;
        // 4xx: error del cliente → no reintentar
        return false;

      // Cancelación, certificado, desconocido → no reintentar
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return false;
    }
  }

  /// Calcula el delay con backoff exponencial y jitter aleatorio (±20%).
  int _computeDelay(int attempt) {
    final expo = baseDelayMs * pow(2, attempt).toInt();
    final capped = min(expo, maxDelayMs);
    // Jitter: ±20% para evitar que todos los clientes reintenten a la vez
    final jitter = (capped * 0.2 * (Random().nextDouble() * 2 - 1)).toInt();
    return max(0, capped + jitter);
  }
}
