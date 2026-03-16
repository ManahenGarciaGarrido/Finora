import '../../domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.type,
    super.creditorName,
    required super.amount,
    required super.remainingAmount,
    required super.interestRate,
    super.dueDate,
    super.monthlyPayment,
    super.notes,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  static double _d(dynamic v, [double f = 0.0]) {
    if (v == null) return f;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? f;
  }

  factory DebtModel.fromJson(Map<String, dynamic> j) => DebtModel(
    id: j['id'] as String,
    userId: j['user_id'] as String? ?? '',
    name: j['name'] as String,
    type: j['type'] as String? ?? 'own',
    creditorName: j['creditor_name'] as String?,
    amount: _d(j['amount']),
    remainingAmount: _d(j['remaining_amount']),
    interestRate: _d(j['interest_rate']),
    dueDate: j['due_date'] != null
        ? DateTime.tryParse(j['due_date'].toString())
        : null,
    monthlyPayment: j['monthly_payment'] != null
        ? _d(j['monthly_payment'])
        : null,
    notes: j['notes'] as String?,
    isActive: j['is_active'] as bool? ?? true,
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'creditor_name': creditorName,
    'amount': amount,
    'remaining_amount': remainingAmount,
    'interest_rate': interestRate,
    'due_date': dueDate?.toIso8601String().split('T').first,
    'monthly_payment': monthlyPayment,
    'notes': notes,
  };
}
