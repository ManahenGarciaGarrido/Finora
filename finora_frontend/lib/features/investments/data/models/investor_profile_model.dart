import '../../domain/entities/investor_profile_entity.dart';

class InvestorProfileModel extends InvestorProfileEntity {
  const InvestorProfileModel({
    required super.id,
    required super.riskTolerance,
    required super.investmentHorizon,
    super.monthlyCapacity,
    required super.createdAt,
    required super.updatedAt,
  });

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory InvestorProfileModel.fromJson(Map<String, dynamic> j) =>
      InvestorProfileModel(
        id: j['id'] as String,
        riskTolerance: j['risk_tolerance'] as String,
        investmentHorizon: j['investment_horizon'] as String,
        monthlyCapacity: _d(j['monthly_capacity']),
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );
}
