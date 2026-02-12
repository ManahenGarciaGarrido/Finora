import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../sync/sync_manager.dart';

/// Servicio de conectividad con sincronización automática (RNF-15)
///
/// Monitoriza el estado de la conexión y dispara la sincronización
/// automáticamente cuando se recupera la conexión.
class ConnectivityService {
  final Connectivity _connectivity;
  final SyncManager _syncManager;

  StreamSubscription<ConnectivityResult>? _subscription;
  final _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _disposed = false;

  ConnectivityService({
    required Connectivity connectivity,
    required SyncManager syncManager,
  })  : _connectivity = connectivity,
        _syncManager = syncManager;

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Inicia la monitorización de conectividad
  Future<void> init() async {
    // Verificar estado inicial
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    // Escuchar cambios
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(result);

      if (!_disposed) {
        _controller.add(_isOnline);
      }

      // Si recuperamos conexión, sincronizar automáticamente
      if (!wasOnline && _isOnline) {
        debugPrint('ConnectivityService: Conexión recuperada, iniciando sincronización...');
        _syncManager.processQueue().then((success) {
          if (success) {
            debugPrint('ConnectivityService: Sincronización completada con éxito');
          } else {
            debugPrint('ConnectivityService: Sincronización parcial o fallida');
          }
        });
      }
    });
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
  }
}
