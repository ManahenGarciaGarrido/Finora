import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/database/local_database.dart';
import '../../../../core/sync/sync_manager.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// BLoC para gestionar transacciones (RF-05, RNF-06, RNF-15)
///
/// Estrategia offline-first:
/// 1. Cargar datos de Hive (instantáneo, < 5ms) → emitir inmediatamente
/// 2. Intentar cargar de API en background → actualizar Hive y UI
/// 3. Si offline, trabajar exclusivamente con datos locales
///
/// Persiste transacciones en Hive y sincroniza con la API cuando hay conexión.
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  final NetworkInfo _networkInfo;
  final SyncManager _syncManager;
  final List<TransactionEntity> _transactions = [];

  TransactionBloc({
    required ApiClient apiClient,
    required LocalDatabase localDatabase,
    required NetworkInfo networkInfo,
    required SyncManager syncManager,
  })  : _apiClient = apiClient,
        _localDatabase = localDatabase,
        _networkInfo = networkInfo,
        _syncManager = syncManager,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<EditTransaction>(_onEditTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<SyncTransactions>(_onSyncTransactions);
  }

  List<TransactionEntity> get transactions => List.unmodifiable(_transactions);

  double get totalBalance {
    double balance = 0;
    for (final t in _transactions) {
      balance += t.isIncome ? t.amount : -t.amount;
    }
    return balance;
  }

  double get totalIncome {
    double total = 0;
    for (final t in _transactions) {
      if (t.isIncome) total += t.amount;
    }
    return total;
  }

  double get totalExpenses {
    double total = 0;
    for (final t in _transactions) {
      if (t.isExpense) total += t.amount;
    }
    return total;
  }

  /// Calcula gastos agrupados por categoría
  Map<String, double> get expensesByCategory {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.isExpense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  /// Cargar transacciones: primero local (Hive), luego API en background
  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    // Paso 1: Cargar datos locales de Hive (instantáneo, < 5ms)
    final localData = _localDatabase.getAllTransactions();
    if (localData.isNotEmpty) {
      _transactions.clear();
      for (final map in localData) {
        _transactions.add(TransactionEntity.fromMap(map));
      }
      // Ordenar por fecha (más reciente primero)
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _emitLoaded(emit, isOffline: false);
    }

    // Paso 2: Intentar cargar de API en background
    try {
      final isConnected = await _networkInfo.isConnected;
      if (!isConnected) {
        // Sin conexión: emitir datos locales con flag offline
        if (localData.isEmpty) {
          _emitLoaded(emit, isOffline: true);
        } else {
          _emitLoaded(emit, isOffline: true);
        }
        return;
      }

      // Primero sincronizar cola pendiente
      if (_syncManager.pendingCount > 0) {
        await _syncManager.processQueue();
      }

      final response = await _apiClient.get(
        ApiEndpoints.transactions,
        queryParameters: {'limit': 100},
      );

      final data = response.data;
      if (data != null && data['transactions'] != null) {
        _transactions.clear();
        final List<Map<String, dynamic>> serverTransactions = [];

        for (final json in data['transactions']) {
          final entity = _fromJson(json);
          _transactions.add(entity);
          serverTransactions.add(entity.toMap());
        }

        // Añadir transacciones locales pendientes que no están en el servidor
        final localPending = _localDatabase.getAllTransactions()
            .where((t) => t['sync_status'] == 'pending')
            .toList();
        for (final pendingMap in localPending) {
          final pending = TransactionEntity.fromMap(pendingMap);
          // Solo añadir si no existe ya (por ID)
          if (!_transactions.any((t) => t.id == pending.id)) {
            _transactions.add(pending);
            serverTransactions.add(pendingMap);
          }
        }

        // Ordenar por fecha
        _transactions.sort((a, b) => b.date.compareTo(a.date));

        // Guardar en Hive para acceso offline
        await _localDatabase.saveAllTransactions(serverTransactions);
      }

      _emitLoaded(emit, isOffline: false);
    } catch (e) {
      debugPrint('TransactionBloc: Error cargando de API: $e');
      // Si ya tenemos datos locales, los usamos
      _emitLoaded(emit, isOffline: true);
    }
  }

  /// Agregar transacción: guardar en Hive primero, luego API si hay conexión
  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      // Online: intentar enviar a API
      try {
        final t = event.transaction;
        final response = await _apiClient.post(
          ApiEndpoints.transactions,
          data: t.toApiMap(),
        );

        final saved = _fromJson(response.data['transaction']);
        _transactions.insert(0, saved);

        // Guardar en Hive como synced
        await _localDatabase.saveTransaction(saved.toMap());

        emit(TransactionAdded(transaction: saved));
        _emitLoaded(emit);
        return;
      } catch (e) {
        // Diferenciar entre errores de validación y errores de conexión
        debugPrint('TransactionBloc: Error API - $e');

        // Intentar extraer mensaje de error del servidor
        String errorMessage = 'Error al registrar la transacción';
        if (e.toString().contains('Validation Error')) {
          // Error de validación del servidor
          errorMessage = _extractValidationError(e);
          emit(TransactionError(message: errorMessage));
          return; // Detener aquí, no guardar offline
        }

        // Para otros errores (conexión, servidor), guardar offline y notificar
        debugPrint('TransactionBloc: Error API, guardando offline: $e');
      }
    }

    // Offline o fallo de conexión: guardar localmente
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final transaction = event.transaction.copyWith(
      id: localId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );

    _transactions.insert(0, transaction);

    // Guardar en Hive
    await _localDatabase.saveTransaction(transaction.toMap());

    // Encolar para sincronización
    final apiData = transaction.toApiMap();
    apiData['local_id'] = localId;
    await _syncManager.enqueueCreate(apiData);

    // Emitir estado con información de guardado offline
    if (!isConnected) {
      emit(TransactionAdded(
        transaction: transaction,
      ));
      // Mostrar SnackBar informativo de guardado offline
      debugPrint('TransactionBloc: Transacción guardada offline, se sincronizará cuando haya conexión');
    } else {
      emit(TransactionAdded(transaction: transaction));
    }

    _emitLoaded(emit, isOffline: !isConnected);
  }

  /// Extrae mensaje de error de validación desde la excepción
  String _extractValidationError(dynamic error) {
    final errorStr = error.toString();

    // Intentar extraer mensaje específico de error
    if (errorStr.contains('cantidad')) {
      return 'La cantidad debe ser un número positivo mayor que 0';
    }
    if (errorStr.contains('tipo')) {
      return 'El tipo debe ser ingreso o gasto';
    }
    if (errorStr.contains('categoría')) {
      return 'La categoría es requerida';
    }
    if (errorStr.contains('fecha')) {
      return 'La fecha debe ser una fecha válida';
    }
    if (errorStr.contains('método de pago')) {
      return 'El método de pago es inválido';
    }
    if (errorStr.contains('descripción')) {
      return 'La descripción no puede exceder 500 caracteres';
    }

    return 'Error de validación en los datos. Por favor, revisa los campos e intenta de nuevo';
  }

  /// Editar transacción: actualizar en Hive, luego API si hay conexión (RF-06)
  Future<void> _onEditTransaction(
    EditTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final t = event.transaction;
    final index = _transactions.indexWhere((tx) => tx.id == t.id);
    if (index == -1) {
      emit(TransactionError(message: 'Transacción no encontrada'));
      _emitLoaded(emit);
      return;
    }

    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        final response = await _apiClient.put(
          ApiEndpoints.transactionById(t.id!),
          data: t.toApiMap(),
        );

        // Usar los datos devueltos por el servidor (incluye updated_at real)
        final serverData = response.data['transaction'];
        final updated = serverData != null
            ? _fromJson(serverData)
            : t.copyWith(
                updatedAt: DateTime.now(),
                syncStatus: SyncStatus.synced,
              );

        _transactions[index] = updated;
        await _localDatabase.updateTransaction(t.id!, updated.toMap());

        emit(TransactionUpdated(transaction: updated));
        _emitLoaded(emit);
        return;
      } catch (e) {
        debugPrint('TransactionBloc: Error editando en API: $e');

        // Intentar extraer mensaje de validación
        String errorMessage = 'Error al actualizar la transacción';
        if (e.toString().contains('Validation Error')) {
          errorMessage = _extractValidationError(e);
          emit(TransactionError(message: errorMessage));
          return;
        }
        // Para errores de conexión, continuar con guardado offline
      }
    }

    // Offline: actualizar localmente y encolar
    final updated = t.copyWith(
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.pending,
    );
    _transactions[index] = updated;
    await _localDatabase.updateTransaction(t.id!, updated.toMap());

    final apiData = updated.toApiMap();
    apiData['id'] = t.id;
    await _syncManager.enqueueUpdate(apiData);

    emit(TransactionUpdated(transaction: updated));
    _emitLoaded(emit, isOffline: !isConnected);
  }

  /// Eliminar transacción: eliminar de Hive, luego API si hay conexión
  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());

    final isConnected = await _networkInfo.isConnected;

    if (isConnected) {
      try {
        await _apiClient.delete(
          ApiEndpoints.transactionById(event.transactionId),
        );
      } catch (_) {
        // Eliminamos localmente de todas formas
      }
    } else {
      // Offline: encolar delete solo si no es un ID local
      if (!event.transactionId.startsWith('local_')) {
        await _syncManager.enqueueDelete(event.transactionId);
      }
    }

    _transactions.removeWhere((t) => t.id == event.transactionId);
    await _localDatabase.deleteTransaction(event.transactionId);

    emit(TransactionDeleted());
    _emitLoaded(emit, isOffline: !isConnected);
  }

  /// Sincronizar manualmente las transacciones pendientes
  Future<void> _onSyncTransactions(
    SyncTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      _emitLoaded(emit, isOffline: true);
      return;
    }

    emit(TransactionsSyncing());

    final success = await _syncManager.processQueue();
    if (success) {
      // Recargar datos del servidor
      add(LoadTransactions());
    } else {
      _emitLoaded(emit);
    }
  }

  void _emitLoaded(Emitter<TransactionState> emit, {bool isOffline = false}) {
    emit(TransactionsLoaded(
      transactions: List.unmodifiable(_transactions),
      balance: totalBalance,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      isOffline: isOffline,
      pendingSyncCount: _syncManager.pendingCount,
    ));
  }

  TransactionEntity _fromJson(Map<String, dynamic> json) {
    return TransactionEntity(
      id: json['id'],
      amount: (json['amount'] is String)
          ? double.parse(json['amount'])
          : (json['amount'] as num).toDouble(),
      type: TransactionType.fromString(json['type']),
      category: json['category'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      paymentMethod: PaymentMethod.fromString(json['payment_method']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      syncStatus: SyncStatus.synced,
    );
  }
}
