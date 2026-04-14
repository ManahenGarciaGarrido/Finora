import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/banks/data/datasources/bank_remote_datasource.dart';
import 'package:finora_frontend/features/banks/data/models/bank_account_model.dart';
import 'package:finora_frontend/features/banks/data/models/bank_card_model.dart';
import 'package:finora_frontend/features/banks/data/repositories/bank_repository_impl.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_account_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_card_entity.dart';

import 'bank_repository_impl_test.mocks.dart';

@GenerateMocks([BankRemoteDataSource])
void main() {
  late MockBankRemoteDataSource mockDs;
  late BankRepositoryImpl repository;

  final tAccountModel = BankAccountModel.fromJson(<String, dynamic>{
    'id': 'acc-1',
    'connection_id': 'conn-1',
    'account_name': 'Cuenta Corriente',
    'balance_cents': 150050,
  });

  final tCardModel = BankCardModel.fromJson(<String, dynamic>{
    'id': 'card-1',
    'bank_account_id': 'acc-1',
    'user_id': 'user-1',
    'card_name': 'Visa',
  });

  setUp(() {
    mockDs = MockBankRemoteDataSource();
    repository = BankRepositoryImpl(remoteDataSource: mockDs);
  });

  group('getBankAccounts', () {
    test('delega al datasource y retorna lista de entidades', () async {
      when(mockDs.getBankAccounts()).thenAnswer((_) async => [tAccountModel]);

      final result = await repository.getBankAccounts();

      expect(result, isA<List<BankAccountEntity>>());
      expect(result.first.id, 'acc-1');
      verify(mockDs.getBankAccounts()).called(1);
    });
  });

  group('connectBank', () {
    test('delega al datasource con institutionId', () async {
      final tResult = <String, dynamic>{
        'connectionId': 'conn-1',
        'authUrl': 'https://auth.url',
      };
      when(mockDs.connectBank('inst-1')).thenAnswer((_) async => tResult);

      final result = await repository.connectBank('inst-1');

      expect(result['connectionId'], 'conn-1');
      verify(mockDs.connectBank('inst-1')).called(1);
    });
  });

  group('disconnectBank', () {
    test('delega al datasource con connectionId', () async {
      when(mockDs.disconnectBank('conn-1')).thenAnswer((_) async {
        return;
      });

      await repository.disconnectBank('conn-1');

      verify(mockDs.disconnectBank('conn-1')).called(1);
    });
  });

  group('syncBank', () {
    test('delega al datasource y retorna cuentas actualizadas', () async {
      when(mockDs.syncBank('conn-1')).thenAnswer((_) async => [tAccountModel]);

      final result = await repository.syncBank('conn-1');

      expect(result.first.balanceCents, 150050);
    });
  });

  group('getBankCards', () {
    test('retorna lista de BankCardEntity', () async {
      when(mockDs.getBankCards()).thenAnswer((_) async => [tCardModel]);

      final result = await repository.getBankCards();

      expect(result, isA<List<BankCardEntity>>());
      expect(result.first.id, 'card-1');
    });
  });

  group('deleteBankCard', () {
    test('delega al datasource con cardId', () async {
      when(mockDs.deleteBankCard('card-1')).thenAnswer((_) async {
        return;
      });

      await repository.deleteBankCard('card-1');

      verify(mockDs.deleteBankCard('card-1')).called(1);
    });
  });

  group('importCsvTransactions', () {
    test('delega y retorna mapa con imported/skipped', () async {
      final tResult = <String, int>{'imported': 10, 'skipped': 0};

      when(
        mockDs.importCsvTransactions(
          bankAccountId: anyNamed('bankAccountId'),
          rows: anyNamed('rows'),
        ),
      ).thenAnswer((_) async => tResult);

      final result = await repository.importCsvTransactions(
        bankAccountId: 'acc-1',
        rows: [],
      );

      expect(result['imported'], 10);
    });
  });

  group('importBankTransactions', () {
    test('delega y retorna mapa de sincronización', () async {
      final tResult = <String, dynamic>{
        'imported': 25,
        'skipped': 0,
        'last_sync_at': '2024-06-01',
      };
      when(
        mockDs.importBankTransactions('conn-1', fromDate: '2024-01-01'),
      ).thenAnswer((_) async => tResult);

      final result = await repository.importBankTransactions(
        'conn-1',
        fromDate: '2024-01-01',
      );

      expect(result['imported'], 25);
    });
  });

  group('exchangePublicToken', () {
    test('delega al datasource con los parámetros correctos', () async {
      when(
        mockDs.exchangePublicToken(
          connectionId: 'conn-1',
          publicToken: 'pub-tok-123',
          institutionName: 'Santander',
        ),
      ).thenAnswer((_) async {
        return;
      });

      await repository.exchangePublicToken(
        connectionId: 'conn-1',
        publicToken: 'pub-tok-123',
        institutionName: 'Santander',
      );

      verify(
        mockDs.exchangePublicToken(
          connectionId: 'conn-1',
          publicToken: 'pub-tok-123',
          institutionName: 'Santander',
        ),
      ).called(1);
    });
  });
}
