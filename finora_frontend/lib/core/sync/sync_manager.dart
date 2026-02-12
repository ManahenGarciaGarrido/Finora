import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../database/local_database.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import 'sync_queue_item.dart';

/// Gestor de sincronización offline (RNF-15)
///
/// Procesa la cola FIFO de operaciones pendientes cuando hay conexión.
/// Actualiza IDs locales con IDs del servidor tras crear transacciones.
/// Maneja conflictos con estrategia de timestamp del servidor prevalece.
class SyncManager {
  final LocalDatabase _localDatabase;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  bool _isSyncing = false;

  SyncManager({
    required LocalDatabase localDatabase,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _localDatabase = localDatabase,
        _apiClient = apiClient,
        _networkInfo = networkInfo;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _localDatabase.pendingSyncCount;

  /// Procesa toda la cola de sincronización
  /// Retorna true si todas las operaciones se sincronizaron correctamente
  Future<bool> processQueue() async {
    if (_isSyncing) return false;

    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) return false;

    _isSyncing = true;
    var allSuccess = true;

    try {
      final queueItems = _localDatabase.getSyncQueue();
      if (queueItems.isEmpty) return true;

      // Ordenar por fecha de creación (FIFO)
      queueItems.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return aTime.compareTo(bTime);
      });

      for (final itemMap in queueItems) {
        final item = SyncQueueItem.fromMap(itemMap);

        if (item.hasExceededRetries) {
          // Marcar la transacción local como error de sync
          _markTransactionSyncError(item);
          await _localDatabase.removeFromSyncQueue(item.id);
          continue;
        }

        final success = await _processSingleItem(item);
        if (!success) {
          allSuccess = false;
          // Incrementar retry count
          final updated = item.copyWithRetry();
          await _localDatabase.updateSyncQueueItem(item.id, updated.toMap());
        } else {
          await _localDatabase.removeFromSyncQueue(item.id);
        }
      }

      if (allSuccess) {
        await _localDatabase.setLastSyncTime(DateTime.now());
      }
    } catch (e) {
      debugPrint('SyncManager: Error procesando cola: $e');
      allSuccess = false;
    } finally {
      _isSyncing = false;
    }

    return allSuccess;
  }

  /// Procesa un solo item de la cola
  Future<bool> _processSingleItem(SyncQueueItem item) async {
    try {
      switch (item.action) {
        case 'create':
          return await _syncCreate(item);
        case 'update':
          return await _syncUpdate(item);
        case 'delete':
          return await _syncDelete(item);
        default:
          debugPrint('SyncManager: Acción desconocida: ${item.action}');
          return false;
      }
    } catch (e) {
      debugPrint('SyncManager: Error sincronizando ${item.action}: $e');
      return false;
    }
  }

  /// Sincroniza una operación de creación
  Future<bool> _syncCreate(SyncQueueItem item) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.transactions,
        data: item.data,
      );

      // Actualizar la transacción local con el ID del servidor
      final serverTransaction = response.data['transaction'];
      if (serverTransaction != null) {
        final localId = item.data['local_id'] ?? item.data['id'];
        if (localId != null) {
          // Eliminar la transacción con ID temporal
          await _localDatabase.deleteTransaction(localId.toString());
          // Guardar con el ID del servidor
          final updatedMap = Map<String, dynamic>.from(item.data);
          updatedMap['id'] = serverTransaction['id'];
          updatedMap['sync_status'] = 'synced';
          updatedMap['created_at'] = serverTransaction['created_at'];
          updatedMap['updated_at'] = serverTransaction['updated_at'];
          await _localDatabase.saveTransaction(updatedMap);
        }
      }

      return true;
    } catch (e) {
      debugPrint('SyncManager: Error en create sync: $e');
      return false;
    }
  }

  /// Sincroniza una operación de actualización
  Future<bool> _syncUpdate(SyncQueueItem item) async {
    try {
      final id = item.data['id'];
      if (id == null) return false;

      await _apiClient.put(
        ApiEndpoints.transactionById(id.toString()),
        data: item.data,
      );

      // Actualizar sync_status local
      final localData = Map<String, dynamic>.from(item.data);
      localData['sync_status'] = 'synced';
      await _localDatabase.updateTransaction(id.toString(), localData);

      return true;
    } catch (e) {
      // Si el servidor devuelve 404, la transacción ya no existe
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        await _localDatabase.deleteTransaction(item.data['id'].toString());
        return true;
      }
      debugPrint('SyncManager: Error en update sync: $e');
      return false;
    }
  }

  /// Sincroniza una operación de eliminación
  Future<bool> _syncDelete(SyncQueueItem item) async {
    try {
      final id = item.data['id'];
      if (id == null) return false;

      await _apiClient.delete(
        ApiEndpoints.transactionById(id.toString()),
      );
      return true;
    } catch (e) {
      // Si ya fue eliminada en el servidor (404), considerar como éxito
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return true;
      }
      debugPrint('SyncManager: Error en delete sync: $e');
      return false;
    }
  }

  /// Marca una transacción local como error de sincronización
  void _markTransactionSyncError(SyncQueueItem item) {
    final id = item.data['id']?.toString() ?? item.data['local_id']?.toString();
    if (id != null) {
      final transactions = _localDatabase.getAllTransactions();
      for (final t in transactions) {
        if (t['id']?.toString() == id) {
          t['sync_status'] = 'error';
          _localDatabase.updateTransaction(id, t);
          break;
        }
      }
    }
  }

  /// Encola una operación de creación
  Future<void> enqueueCreate(Map<String, dynamic> transactionData) async {
    final item = SyncQueueItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      action: 'create',
      entityType: 'transaction',
      data: transactionData,
      createdAt: DateTime.now(),
    );
    await _localDatabase.addToSyncQueue(item.toMap());
  }

  /// Encola una operación de actualización
  Future<void> enqueueUpdate(Map<String, dynamic> transactionData) async {
    final item = SyncQueueItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      action: 'update',
      entityType: 'transaction',
      data: transactionData,
      createdAt: DateTime.now(),
    );
    await _localDatabase.addToSyncQueue(item.toMap());
  }

  /// Encola una operación de eliminación
  Future<void> enqueueDelete(String transactionId) async {
    final item = SyncQueueItem(
      id: 'sync_${DateTime.now().millisecondsSinceEpoch}',
      action: 'delete',
      entityType: 'transaction',
      data: {'id': transactionId},
      createdAt: DateTime.now(),
    );
    await _localDatabase.addToSyncQueue(item.toMap());
  }
}
