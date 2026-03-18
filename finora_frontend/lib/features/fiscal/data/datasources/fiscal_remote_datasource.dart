import 'dart:developer' as dev;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/fiscal_models.dart';

abstract class FiscalRemoteDataSource {
  Future<List<FiscalTransactionModel>> getDeductibles({int? year});
  Future<List<FiscalTransactionModel>> getAllTransactions({int? year});
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
  Future<Uint8List> downloadExport({int? year, required String format});
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
    dev.log(
      '[FISCAL] tagTransaction → id="$transactionId" category="$fiscalCategory"',
      name: 'FiscalDS',
    );
    try {
      final res = await _client.patch(
        '/fiscal/tag/$transactionId',
        data: {'fiscal_category': fiscalCategory},
      );
      dev.log(
        '[FISCAL] tagTransaction fiscal SUCCESS → ${res.data}',
        name: 'FiscalDS',
      );
      return FiscalTransactionModel.fromJson(
        res.data['transaction'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      dev.log(
        '[FISCAL] tagTransaction fiscal ERROR → status=$status '
        'body=${e.response?.data} url=${e.requestOptions.uri}',
        name: 'FiscalDS',
      );
      // Fallback: /fiscal/tag/{id} only works for transactions already in the
      // fiscal system. For general transactions (from /transactions endpoint),
      // update fiscal_category directly on the transaction record.
      if (status == 404) {
        dev.log(
          '[FISCAL] tagTransaction 404 → falling back to PATCH /transactions/$transactionId',
          name: 'FiscalDS',
        );
        final fallbackRes = await _client.patch(
          '/transactions/$transactionId',
          data: {'fiscal_category': fiscalCategory},
        );
        dev.log(
          '[FISCAL] tagTransaction /transactions PATCH SUCCESS → ${fallbackRes.data}',
          name: 'FiscalDS',
        );
        final tx =
            fallbackRes.data['transaction'] as Map<String, dynamic>? ?? {};
        return FiscalTransactionModel(
          id: tx['id']?.toString() ?? transactionId,
          description: tx['description']?.toString() ?? '',
          amount: double.tryParse(tx['amount']?.toString() ?? '') ?? 0.0,
          date: tx['date']?.toString() ?? tx['created_at']?.toString() ?? '',
          category: tx['category']?.toString(),
          fiscalCategory: tx['fiscal_category']?.toString() ?? fiscalCategory,
        );
      }
      rethrow;
    }
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
  Future<List<FiscalTransactionModel>> getAllTransactions({int? year}) async {
    final params = year != null ? '?year=$year' : '';
    dev.log(
      '[FISCAL] getAllTransactions → GET /fiscal/all-transactions$params',
      name: 'FiscalDS',
    );

    final res = await _client.get('/fiscal/all-transactions$params');
    dev.log(
      '[FISCAL] /fiscal/all-transactions response keys: ${res.data?.keys?.toList()}',
      name: 'FiscalDS',
    );

    final list = res.data['transactions'] as List? ?? [];
    dev.log(
      '[FISCAL] /fiscal/all-transactions returned ${list.length} items',
      name: 'FiscalDS',
    );

    if (list.isNotEmpty) {
      dev.log(
        '[FISCAL] Using fiscal endpoint data. First item keys: ${(list.first as Map).keys.toList()}',
        name: 'FiscalDS',
      );
      return list
          .map(
            (e) => FiscalTransactionModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    // Fallback: fetch from general transactions endpoint.
    // Try page=0 first (0-indexed), then page=1 (1-indexed) if empty.
    dev.log(
      '[FISCAL] Fiscal endpoint empty → falling back to /transactions',
      name: 'FiscalDS',
    );

    List txList = [];
    for (final url in [
      '/transactions?limit=500&page=0',
      '/transactions?limit=500&page=1',
      '/transactions?limit=500',
    ]) {
      try {
        dev.log('[FISCAL] Trying fallback URL: $url', name: 'FiscalDS');
        final fallback = await _client.get(url);
        dev.log(
          '[FISCAL] $url → keys: ${fallback.data?.keys?.toList()}',
          name: 'FiscalDS',
        );
        final candidate =
            (fallback.data['transactions'] as List?) ??
            (fallback.data['data'] as List?) ??
            [];
        dev.log('[FISCAL] $url → ${candidate.length} items', name: 'FiscalDS');
        if (candidate.isNotEmpty) {
          txList = candidate;
          break;
        }
      } on DioException catch (e) {
        dev.log(
          '[FISCAL] $url → DioException status=${e.response?.statusCode} body=${e.response?.data}',
          name: 'FiscalDS',
        );
      }
    }
    dev.log(
      '[FISCAL] /transactions final count: ${txList.length} items',
      name: 'FiscalDS',
    );

    if (txList.isNotEmpty) {
      final first = txList.first as Map<String, dynamic>;
      dev.log(
        '[FISCAL] First tx keys: ${first.keys.toList()}',
        name: 'FiscalDS',
      );
      dev.log('[FISCAL] First tx data: $first', name: 'FiscalDS');
    }

    return txList.map((e) {
      final m = e as Map<String, dynamic>;
      final id =
          m['id']?.toString() ??
          m['_id']?.toString() ??
          m['transaction_id']?.toString() ??
          '';
      dev.log(
        '[FISCAL] Mapping tx id="$id" desc="${m['description']}" amount="${m['amount']}"',
        name: 'FiscalDS',
      );
      return FiscalTransactionModel(
        id: id,
        description: m['description']?.toString() ?? '',
        amount: double.tryParse(m['amount']?.toString() ?? '') ?? 0.0,
        date: m['date']?.toString() ?? m['created_at']?.toString() ?? '',
        category: m['category']?.toString(),
        fiscalCategory: null,
      );
    }).toList();
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

  @override
  Future<Uint8List> downloadExport({int? year, required String format}) async {
    final y = year ?? DateTime.now().year;
    final res = await _client.get(
      '/fiscal/export?year=$y&format=$format',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data as List<int>);
  }
}
