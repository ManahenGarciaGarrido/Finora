import '../../domain/entities/fiscal_transaction_entity.dart';
import '../../domain/entities/irpf_result_entity.dart';
import '../../domain/entities/tax_event_entity.dart';

double _d(dynamic v, [double fallback = 0.0]) =>
    v == null ? fallback : double.tryParse(v.toString()) ?? fallback;

class FiscalTransactionModel extends FiscalTransactionEntity {
  const FiscalTransactionModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.date,
    super.category,
    super.fiscalCategory,
  });

  factory FiscalTransactionModel.fromJson(Map<String, dynamic> j) =>
      FiscalTransactionModel(
        id: j['id']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        amount: _d(j['amount']),
        date: j['date']?.toString() ?? '',
        category: j['category']?.toString(),
        fiscalCategory: j['fiscal_category']?.toString(),
      );
}

class TaxBracketModel extends TaxBracketEntity {
  const TaxBracketModel({
    required super.from,
    super.to,
    required super.rate,
    required super.taxableAmount,
    required super.tax,
  });

  factory TaxBracketModel.fromJson(Map<String, dynamic> j) => TaxBracketModel(
    from: _d(j['from']),
    to: j['to'] != null ? _d(j['to']) : null,
    rate: _d(j['rate']),
    taxableAmount: _d(j['taxable_amount']),
    tax: _d(j['tax']),
  );
}

class IrpfResultModel extends IrpfResultEntity {
  const IrpfResultModel({
    required super.annualIncome,
    required super.deductibleTotal,
    required super.taxableBase,
    required super.estimatedTax,
    required super.netIncome,
    required super.effectiveRate,
    required super.brackets,
  });

  factory IrpfResultModel.fromJson(Map<String, dynamic> j) {
    final bracketList = (j['brackets'] as List? ?? [])
        .map((e) => TaxBracketModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return IrpfResultModel(
      annualIncome: _d(j['annual_income']),
      deductibleTotal: _d(j['deductible_total']),
      taxableBase: _d(j['taxable_base']),
      estimatedTax: _d(j['estimated_tax']),
      netIncome: _d(j['net_income']),
      effectiveRate: _d(j['effective_rate']),
      brackets: bracketList,
    );
  }
}

class TaxEventModel extends TaxEventEntity {
  const TaxEventModel({
    required super.date,
    required super.title,
    required super.type,
  });

  factory TaxEventModel.fromJson(Map<String, dynamic> j) => TaxEventModel(
    date: j['date']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    type: j['type']?.toString() ?? '',
  );
}
