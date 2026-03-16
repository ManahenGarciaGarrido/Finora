class DebtEntity {
  final String id;
  final String userId;
  final String name;
  final String type; // 'own' | 'owed'
  final String? creditorName;
  final double amount;
  final double remainingAmount;
  final double interestRate;
  final DateTime? dueDate;
  final double? monthlyPayment;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DebtEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.creditorName,
    required this.amount,
    required this.remainingAmount,
    required this.interestRate,
    this.dueDate,
    this.monthlyPayment,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOwn => type == 'own';
  double get paidAmount => amount - remainingAmount;
  double get progressPercent => amount > 0 ? (paidAmount / amount) * 100 : 0;
}
