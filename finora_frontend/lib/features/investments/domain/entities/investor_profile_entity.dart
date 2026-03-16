class InvestorProfileEntity {
  final String id;
  final String riskTolerance; // conservative | moderate | aggressive
  final String investmentHorizon; // short | medium | long
  final double? monthlyCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InvestorProfileEntity({
    required this.id,
    required this.riskTolerance,
    required this.investmentHorizon,
    this.monthlyCapacity,
    required this.createdAt,
    required this.updatedAt,
  });
}
