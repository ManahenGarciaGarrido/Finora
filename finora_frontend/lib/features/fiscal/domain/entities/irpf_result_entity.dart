class TaxBracketEntity {
  final double from;
  final double? to;
  final double rate;
  final double taxableAmount;
  final double tax;

  const TaxBracketEntity({
    required this.from,
    this.to,
    required this.rate,
    required this.taxableAmount,
    required this.tax,
  });
}

class IrpfResultEntity {
  final double annualIncome;
  final double deductibleTotal;
  final double taxableBase;
  final double estimatedTax;
  final double netIncome;
  final double effectiveRate;
  final List<TaxBracketEntity> brackets;

  const IrpfResultEntity({
    required this.annualIncome,
    required this.deductibleTotal,
    required this.taxableBase,
    required this.estimatedTax,
    required this.netIncome,
    required this.effectiveRate,
    required this.brackets,
  });
}
