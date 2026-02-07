/// Entidad de Transacción del dominio
///
/// Representa una transacción financiera (ingreso o gasto)
/// según el requisito RF-05
class TransactionEntity {
  final String? id;
  final double amount;
  final TransactionType type;
  final String category;
  final String? description;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TransactionEntity({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    required this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  TransactionEntity copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    PaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
}

/// Tipo de transacción
enum TransactionType {
  income,
  expense;

  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.expense:
        return 'Gasto';
    }
  }

  String get apiValue {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
    }
  }

  static TransactionType fromString(String value) {
    switch (value) {
      case 'income':
        return TransactionType.income;
      case 'expense':
        return TransactionType.expense;
      default:
        throw ArgumentError('Invalid transaction type: $value');
    }
  }
}

/// Método de pago
enum PaymentMethod {
  cash,
  card,
  transfer;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.transfer:
        return 'Transferencia';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.transfer:
        return 'transfer';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'transfer':
        return PaymentMethod.transfer;
      default:
        throw ArgumentError('Invalid payment method: $value');
    }
  }
}

/// Categorías predefinidas de transacciones
class TransactionCategories {
  TransactionCategories._();

  static const List<String> expenseCategories = [
    'Alimentación',
    'Transporte',
    'Vivienda',
    'Ocio',
    'Salud',
    'Educación',
    'Ropa',
    'Suscripciones',
    'Facturas',
    'Compras',
    'Restaurantes',
    'Otros',
  ];

  static const List<String> incomeCategories = [
    'Salario',
    'Freelance',
    'Inversiones',
    'Ventas',
    'Regalos',
    'Reembolsos',
    'Otros',
  ];

  static List<String> forType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return expenseCategories;
      case TransactionType.income:
        return incomeCategories;
    }
  }
}
