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

/// Editar una transacción existente (RNF-15 - offline)
class EditTransaction extends TransactionEvent {
  final TransactionEntity transaction;

  EditTransaction({required this.transaction});
}

/// Eliminar una transacción
class DeleteTransaction extends TransactionEvent {
  final String transactionId;

  DeleteTransaction({required this.transactionId});
}

/// Sincronizar transacciones pendientes con el servidor (RNF-15)
class SyncTransactions extends TransactionEvent {}

/// RNF-20: Cargar la siguiente página de transacciones desde el servidor
/// Se dispara cuando el usuario llega al final de la lista cargada en memoria.
class LoadMoreTransactions extends TransactionEvent {}
