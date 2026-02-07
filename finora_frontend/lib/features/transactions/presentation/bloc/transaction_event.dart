import '../../domain/entities/transaction_entity.dart';

/// Eventos del BLoC de transacciones
abstract class TransactionEvent {}

/// Cargar todas las transacciones
class LoadTransactions extends TransactionEvent {}

/// Agregar una nueva transacción (RF-05)
class AddTransaction extends TransactionEvent {
  final TransactionEntity transaction;

  AddTransaction({required this.transaction});
}

/// Eliminar una transacción
class DeleteTransaction extends TransactionEvent {
  final String transactionId;

  DeleteTransaction({required this.transactionId});
}
