import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../sync/sync_manager.dart';

/// Servicio de conectividad con sincronización automática (RNF-15)
///
/// Monitoriza el estado de la conexión y dispara la sincronización
/// automáticamente cuando se recupera la conexión.
/// Incluye delay para esperar a que la red esté realmente lista
/// y reintentos automáticos si el primer intento falla.
class ConnectivityService {
  final Connectivity _connectivity;
  final SyncManager _syncManager;

  StreamSubscription<ConnectivityResult>? _subscription;
  final _controller = StreamController<bool>.broadcast();
  final _syncCompleteController = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _disposed = false;

  ConnectivityService({
    required Connectivity connectivity,
    required SyncManager syncManager,
  })  : _connectivity = connectivity,
        _syncManager = syncManager;

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Stream que emite true cuando la sincronización se completa con éxito
  /// Para que el TransactionBloc pueda recargar datos
  Stream<bool> get onSyncComplete => _syncCompleteController.stream;

  /// Inicia la monitorización de conectividad
  Future<void> init() async {
    // Verificar estado inicial
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    // Si al iniciar ya hay conexión y hay items pendientes, sincronizar
    if (_isOnline && _syncManager.pendingCount > 0) {
      _attemptSync();
    }

    // Escuchar cambios
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(result);

      if (!_disposed) {
        _controller.add(_isOnline);
      }

      // Si recuperamos conexión, sincronizar automáticamente
      if (!wasOnline && _isOnline) {
        debugPrint('ConnectivityService: Conexión recuperada, esperando estabilización de red...');
        _attemptSync();
      }
    });
  }

  /// Intenta sincronizar con delay y reintentos
  Future<void> _attemptSync() async {
    if (_syncManager.pendingCount == 0) return;

    // Esperar 3 segundos para que la red se estabilice (DNS, routing)
    await Future.delayed(const Duration(seconds: 3));
    if (_disposed || !_isOnline) return;

    debugPrint('ConnectivityService: Iniciando sincronización...');
    var success = await _syncManager.processQueue();

    if (success) {
      debugPrint('ConnectivityService: Sincronización completada con éxito');
      if (!_disposed) _syncCompleteController.add(true);
      return;
    }

    // Primer intento falló, reintentar después de 5 segundos
    debugPrint('ConnectivityService: Primer intento falló, reintentando en 5s...');
    await Future.delayed(const Duration(seconds: 5));
    if (_disposed || !_isOnline) return;

    success = await _syncManager.processQueue();
    if (success) {
      debugPrint('ConnectivityService: Sincronización completada en segundo intento');
      if (!_disposed) _syncCompleteController.add(true);
    } else {
      // Tercer intento después de 10 segundos
      debugPrint('ConnectivityService: Segundo intento falló, reintentando en 10s...');
      await Future.delayed(const Duration(seconds: 10));
      if (_disposed || !_isOnline) return;

      success = await _syncManager.processQueue();
      if (success && !_disposed) {
        debugPrint('ConnectivityService: Sincronización completada en tercer intento');
        _syncCompleteController.add(true);
      } else {
        debugPrint('ConnectivityService: Sincronización fallida tras 3 intentos');
      }
    }
  }

  bool _isConnected(ConnectivityResult result) {
    return result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet;
  }

  /// Fuerza una verificación de conectividad
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _controller.close();
    _syncCompleteController.close();
  }
}
