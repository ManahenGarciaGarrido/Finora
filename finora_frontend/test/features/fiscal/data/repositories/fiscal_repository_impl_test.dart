import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/fiscal/data/datasources/fiscal_remote_datasource.dart';
import 'package:finora_frontend/features/fiscal/data/models/fiscal_models.dart';
import 'package:finora_frontend/features/fiscal/data/repositories/fiscal_repository_impl.dart';
import 'package:finora_frontend/features/fiscal/domain/entities/fiscal_transaction_entity.dart';
import 'package:finora_frontend/features/fiscal/domain/entities/irpf_result_entity.dart';

// Importamos los mocks que se generarán
import 'fiscal_repository_impl_test.mocks.dart';

@GenerateMocks([FiscalRemoteDataSource])
void main() {
  late MockFiscalRemoteDataSource mockDs;
  late FiscalRepositoryImpl repository;

  final tTransaction = FiscalTransactionModel.fromJson(const {
    'id': 'tx-1',
    'description': 'Seguro médico',
    'amount': 120.0,
    'date': '2024-01-01',
    'fiscal_category': 'deductible',
  });

  setUp(() {
    mockDs = MockFiscalRemoteDataSource();
    repository = FiscalRepositoryImpl(mockDs);
  });

  group('getDeductibles', () {
    test('delega al datasource y retorna lista de entidades', () async {
      when(
        mockDs.getDeductibles(year: anyNamed('year')),
      ).thenAnswer((_) async => [tTransaction]);

      final result = await repository.getDeductibles(year: 2024);

      expect(result, isA<List<FiscalTransactionEntity>>());
      verify(mockDs.getDeductibles(year: 2024)).called(1);
    });
  });

  group('tagTransaction', () {
    test('delega con transactionId y fiscalCategory correctos', () async {
      when(
        mockDs.tagTransaction(any, any),
      ).thenAnswer((_) async => tTransaction);

      final result = await repository.tagTransaction('tx-1', 'deductible');

      expect(result, isA<FiscalTransactionEntity>());
      verify(mockDs.tagTransaction('tx-1', 'deductible')).called(1);
    });
  });

  group('estimateIrpf', () {
    test('delega con annualIncome y extraDeductions correctos', () async {
      final tResult = IrpfResultModel.fromJson(const {
        'annual_income': 30000.0,
        'deductible_total': 0.0,
        'taxable_base': 30000.0,
        'estimated_tax': 5700.0,
        'net_income': 24300.0,
        'effective_rate': 19.0,
        'brackets': [],
      });

      when(
        mockDs.estimateIrpf(
          annualIncome: anyNamed('annualIncome'),
          extraDeductions: anyNamed('extraDeductions'),
        ),
      ).thenAnswer((_) async => tResult);

      final result = await repository.estimateIrpf(annualIncome: 30000.0);

      expect(result, isA<IrpfResultEntity>());
    });
  });
}

