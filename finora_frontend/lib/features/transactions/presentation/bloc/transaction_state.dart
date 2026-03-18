import '../../domain/entities/transaction_entity.dart';

/// Estados del BLoC de transacciones
abstract class TransactionState {}

/// Estado inicial
class TransactionInitial extends TransactionState {}

/// Cargando
class TransactionLoading extends TransactionState {}

/// Transacciones cargadas exitosamente (RNF-15: incluye estado offline)
class TransactionsLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final double balance;
  final double totalIncome;
  final double totalExpenses;
  final bool isOffline;
  final int pendingSyncCount;

  /// RNF-20: indica si el servidor tiene más páginas por cargar
  final bool hasMorePages;

  TransactionsLoaded({
    required this.transactions,
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
    this.isOffline = false,
    this.pendingSyncCount = 0,
    this.hasMorePages = false,
  });
}

/// Transacción agregada exitosamente
class TransactionAdded extends TransactionState {
  final TransactionEntity transaction;

  TransactionAdded({required this.transaction});
}

/// Transacción actualizada exitosamente (RF-06)
class TransactionUpdated extends TransactionState {
  final TransactionEntity transaction;

  TransactionUpdated({required this.transaction});
}

/// Transacción eliminada
class TransactionDeleted extends TransactionState {}

/// Sincronizando transacciones pendientes (RNF-15)
class TransactionsSyncing extends TransactionState {}

/// Error en transacciones
class TransactionError extends TransactionState {
  final String message;

  TransactionError({required this.message});
}
