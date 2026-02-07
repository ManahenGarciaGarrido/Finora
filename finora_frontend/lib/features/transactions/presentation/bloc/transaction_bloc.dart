import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// BLoC para gestionar transacciones (RF-05)
///
/// Persiste transacciones en la base de datos a través de la API REST.
/// Mantiene una copia local para rendimiento del UI.
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final ApiClient _apiClient;
  final List<TransactionEntity> _transactions = [];

  TransactionBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(TransactionInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
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

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final response = await _apiClient.get(
        ApiEndpoints.transactions,
        queryParameters: {'limit': 100},
      );

      _transactions.clear();
      final data = response.data;
      if (data != null && data['transactions'] != null) {
        for (final json in data['transactions']) {
          _transactions.add(_fromJson(json));
        }
      }

      _emitLoaded(emit);
    } catch (e) {
      // Si falla la red, emitimos lo que tengamos en local
      _emitLoaded(emit);
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      final t = event.transaction;
      final response = await _apiClient.post(
        ApiEndpoints.transactions,
        data: {
          'amount': t.amount,
          'type': t.type.apiValue,
          'category': t.category,
          'description': t.description,
          'date': t.date.toIso8601String(),
          'payment_method': t.paymentMethod.apiValue,
        },
      );

      final saved = _fromJson(response.data['transaction']);
      _transactions.insert(0, saved);

      emit(TransactionAdded(transaction: saved));
      _emitLoaded(emit);
    } catch (e) {
      // Fallback: guardar localmente si la API no está disponible
      final transaction = event.transaction.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _transactions.insert(0, transaction);
      emit(TransactionAdded(transaction: transaction));
      _emitLoaded(emit);
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(TransactionLoading());
    try {
      await _apiClient.delete(
        ApiEndpoints.transactionById(event.transactionId),
      );
    } catch (_) {
      // Eliminamos localmente de todas formas
    }
    _transactions.removeWhere((t) => t.id == event.transactionId);
    emit(TransactionDeleted());
    _emitLoaded(emit);
  }

  void _emitLoaded(Emitter<TransactionState> emit) {
    emit(TransactionsLoaded(
      transactions: List.unmodifiable(_transactions),
      balance: totalBalance,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
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
    );
  }
}
