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
  final String? bankAccountId; // cuenta bancaria asociada (opcional)
  final String? cardId; // tarjeta bancaria asociada (opcional)

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
    this.bankAccountId,
    this.cardId,
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
    String? bankAccountId,
    String? cardId,
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
      bankAccountId: bankAccountId ?? this.bankAccountId,
      cardId: cardId ?? this.cardId,
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
      'bank_account_id': bankAccountId,
      'card_id': cardId,
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
      bankAccountId: map['bank_account_id'],
      cardId: map['card_id'],
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
      if (bankAccountId != null) 'bank_account_id': bankAccountId,
      if (cardId != null) 'card_id': cardId,
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

/// Método de pago — incluye todos los métodos bancarios y digitales
enum PaymentMethod {
  // Efectivo
  cash,
  // Tarjetas
  debitCard,
  creditCard,
  prepaidCard,
  card, // legacy: alias de debitCard para compatibilidad
  // Transferencias
  bankTransfer,
  transfer, // legacy: alias de bankTransfer para compatibilidad
  sepa,
  wire,
  // Pagos digitales / móvil
  bizum,
  paypal,
  applePay,
  googlePay,
  // Otros instrumentos bancarios
  directDebit,
  cheque,
  voucher,
  // Criptomonedas
  crypto;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.debitCard:
        return 'Tarjeta de débito';
      case PaymentMethod.creditCard:
        return 'Tarjeta de crédito';
      case PaymentMethod.prepaidCard:
        return 'Tarjeta prepago';
      case PaymentMethod.card:
        return 'Tarjeta';
      case PaymentMethod.bankTransfer:
        return 'Transferencia bancaria';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.sepa:
        return 'Transferencia SEPA';
      case PaymentMethod.wire:
        return 'Transferencia internacional';
      case PaymentMethod.bizum:
        return 'Bizum';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.directDebit:
        return 'Domiciliación/Recibo';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.voucher:
        return 'Cupón/Vale';
      case PaymentMethod.crypto:
        return 'Criptomonedas';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.debitCard:
        return 'debit_card';
      case PaymentMethod.creditCard:
        return 'credit_card';
      case PaymentMethod.prepaidCard:
        return 'prepaid_card';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.transfer:
        return 'transfer';
      case PaymentMethod.sepa:
        return 'sepa';
      case PaymentMethod.wire:
        return 'wire';
      case PaymentMethod.bizum:
        return 'bizum';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.applePay:
        return 'apple_pay';
      case PaymentMethod.googlePay:
        return 'google_pay';
      case PaymentMethod.directDebit:
        return 'direct_debit';
      case PaymentMethod.cheque:
        return 'cheque';
      case PaymentMethod.voucher:
        return 'voucher';
      case PaymentMethod.crypto:
        return 'crypto';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'debit_card':
        return PaymentMethod.debitCard;
      case 'credit_card':
        return PaymentMethod.creditCard;
      case 'prepaid_card':
        return PaymentMethod.prepaidCard;
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'transfer':
        return PaymentMethod.transfer;
      case 'sepa':
        return PaymentMethod.sepa;
      case 'wire':
        return PaymentMethod.wire;
      case 'bizum':
        return PaymentMethod.bizum;
      case 'paypal':
        return PaymentMethod.paypal;
      case 'apple_pay':
        return PaymentMethod.applePay;
      case 'google_pay':
        return PaymentMethod.googlePay;
      case 'direct_debit':
        return PaymentMethod.directDebit;
      case 'cheque':
        return PaymentMethod.cheque;
      case 'voucher':
        return PaymentMethod.voucher;
      case 'crypto':
        return PaymentMethod.crypto;
      default:
        return PaymentMethod.cash; // fallback graceful
    }
  }

  /// Returns true if this method is associated with a bank card
  bool get isCard =>
      this == PaymentMethod.debitCard ||
      this == PaymentMethod.creditCard ||
      this == PaymentMethod.prepaidCard ||
      this == PaymentMethod.card;

  /// Returns true if this method involves a bank account (not cash)
  bool get isBank =>
      this == PaymentMethod.bankTransfer ||
      this == PaymentMethod.transfer ||
      this == PaymentMethod.sepa ||
      this == PaymentMethod.wire ||
      this == PaymentMethod.directDebit;
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
