/// Entidad de Transacción del dominio
///
/// Representa una transacción financiera (ingreso o gasto)
/// según el requisito RF-05. Incluye estado de sincronización
/// para soporte offline (RNF-15).
class TransactionEntity {
  final String? id;
  final double amount;
  final TransactionType type;
  final String category;
  final String? description;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? photoPath; // HU-03: foto opcional del ticket
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SyncStatus syncStatus;

  const TransactionEntity({
    this.id,
    required this.amount,
    required this.type,
    required this.category,
    this.description,
    required this.date,
    required this.paymentMethod,
    this.photoPath,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = SyncStatus.synced,
  });

  TransactionEntity copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;
  bool get isPendingSync => syncStatus == SyncStatus.pending;
  bool get hasSyncError => syncStatus == SyncStatus.error;

  /// Serializa a Map para almacenamiento en Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.apiValue,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod.apiValue,
      'photo_path': photoPath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sync_status': syncStatus.value,
    };
  }

  /// Deserializa desde Map almacenado en Hive
  factory TransactionEntity.fromMap(Map<String, dynamic> map) {
    return TransactionEntity(
      id: map['id']?.toString(),
      amount: (map['amount'] is String)
          ? double.parse(map['amount'])
          : (map['amount'] as num).toDouble(),
      type: TransactionType.fromString(map['type'] ?? 'expense'),
      category: map['category'] ?? '',
      description: map['description'],
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      paymentMethod: PaymentMethod.fromString(map['payment_method'] ?? 'cash'),
      photoPath: map['photo_path'],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'])
          : null,
      syncStatus: SyncStatus.fromString(map['sync_status'] ?? 'synced'),
    );
  }

  /// Convierte a formato de API (para enviar al servidor)
  Map<String, dynamic> toApiMap() {
    return {
      'amount': amount,
      'type': type.apiValue,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod.apiValue,
    };
  }
}

/// Estado de sincronización de una transacción (RNF-15)
enum SyncStatus {
  synced,
  pending,
  error;

  String get value {
    switch (this) {
      case SyncStatus.synced:
        return 'synced';
      case SyncStatus.pending:
        return 'pending';
      case SyncStatus.error:
        return 'error';
    }
  }

  static SyncStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return SyncStatus.pending;
      case 'error':
        return SyncStatus.error;
      default:
        return SyncStatus.synced;
    }
  }
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

/// Categorías predefinidas de transacciones (RF-15)
///
/// Fallback local cuando el CategoryBloc/API no está disponible.
/// Las categorías ahora se gestionan desde la BD vía CategoryBloc.
class TransactionCategories {
  TransactionCategories._();

  static const List<String> expenseCategories = [
    'Alimentación',
    'Transporte',
    'Ocio',
    'Salud',
    'Vivienda',
    'Servicios',
    'Educación',
    'Ropa',
    'Otros',
  ];

  static const List<String> incomeCategories = [
    'Salario',
    'Freelance',
    'Otros ingresos',
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
