import '../../../../core/network/api_client.dart';
import '../models/fiscal_models.dart';

abstract class FiscalRemoteDataSource {
  Future<List<FiscalTransactionModel>> getDeductibles({int? year});
  Future<FiscalTransactionModel> tagTransaction(
    String transactionId,
    String? fiscalCategory,
  );
  Future<IrpfResultModel> estimateIrpf({
    required double annualIncome,
    double extraDeductions,
  });
  Future<List<TaxEventModel>> getCalendar({int? year});
  Future<List<FiscalTransactionModel>> exportFiscal({int? year});
}

class FiscalRemoteDataSourceImpl implements FiscalRemoteDataSource {
  final ApiClient _client;
  FiscalRemoteDataSourceImpl(this._client);

  @override
  Future<List<FiscalTransactionModel>> getDeductibles({int? year}) async {
    final params = year != null ? '?year=$year' : '';
    final res = await _client.get('/fiscal/deductible$params');
    final list = res.data['transactions'] as List? ?? [];
    return list
        .map((e) => FiscalTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FiscalTransactionModel> tagTransaction(
    String transactionId,
    String? fiscalCategory,
  ) async {
    final res = await _client.patch(
      '/fiscal/tag/$transactionId',
      data: {'fiscal_category': fiscalCategory},
    );
    return FiscalTransactionModel.fromJson(
      res.data['transaction'] as Map<String, dynamic>,
    );
  }

  @override
  Future<IrpfResultModel> estimateIrpf({
    required double annualIncome,
    double extraDeductions = 0,
  }) async {
    final res = await _client.post(
      '/fiscal/irpf',
      data: {
        'annual_income': annualIncome,
        'extra_deductions': extraDeductions,
      },
    );
    return IrpfResultModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<List<TaxEventModel>> getCalendar({int? year}) async {
    final params = year != null ? '?year=$year' : '';
    final res = await _client.get('/fiscal/calendar$params');
    final list = res.data['events'] as List? ?? [];
    return list
        .map((e) => TaxEventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FiscalTransactionModel>> exportFiscal({int? year}) async {
    final params = year != null ? '?year=$year' : '';
    final res = await _client.get('/fiscal/export$params');
    final list = res.data['transactions'] as List? ?? [];
    return list
        .map((e) => FiscalTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
