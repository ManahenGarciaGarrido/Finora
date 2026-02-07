import '../../domain/entities/transaction_entity.dart';

/// Estados del BLoC de transacciones
abstract class TransactionState {}

/// Estado inicial
class TransactionInitial extends TransactionState {}

/// Cargando
class TransactionLoading extends TransactionState {}

/// Transacciones cargadas exitosamente
class TransactionsLoaded extends TransactionState {
  final List<TransactionEntity> transactions;
  final double balance;
  final double totalIncome;
  final double totalExpenses;

  TransactionsLoaded({
    required this.transactions,
    required this.balance,
    required this.totalIncome,
    required this.totalExpenses,
  });
}

/// Transacción agregada exitosamente
class TransactionAdded extends TransactionState {
  final TransactionEntity transaction;

  TransactionAdded({required this.transaction});
}

/// Transacción eliminada
class TransactionDeleted extends TransactionState {}

/// Error en transacciones
class TransactionError extends TransactionState {
  final String message;

  TransactionError({required this.message});
}
