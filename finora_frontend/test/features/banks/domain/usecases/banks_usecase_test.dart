import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/banks/domain/entities/bank_account_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_card_entity.dart';
import 'package:finora_frontend/features/banks/domain/repositories/bank_repository.dart';
import 'package:finora_frontend/features/banks/domain/usecases/get_bank_accounts_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/connect_bank_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/disconnect_bank_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/sync_bank_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/get_bank_cards_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/delete_bank_card_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/import_csv_usecase.dart';

// Importamos el archivo que se generará
import 'banks_usecase_test.mocks.dart';

@GenerateMocks([BankRepository])
void main() {
  late MockBankRepository mockRepo;

  const tAccount = BankAccountEntity(
    id: 'acc-1',
    connectionId: 'conn-1',
    accountName: 'Cuenta Corriente',
    balanceCents: 150050,
  );

  const tCard = BankCardEntity(
    id: 'card-1',
    bankAccountId: 'acc-1',
    userId: 'user-1',
    cardName: 'Visa',
  );

  setUp(() => mockRepo = MockBankRepository());

  group('GetBankAccountsUseCase', () {
    late GetBankAccountsUseCase useCase;
    setUp(() => useCase = GetBankAccountsUseCase(mockRepo));

    test('retorna lista de cuentas bancarias', () async {
      when(mockRepo.getBankAccounts()).thenAnswer((_) async => [tAccount]);

      final result = await useCase();

      expect(result.length, 1);
      expect(result.first.id, 'acc-1');
      verify(mockRepo.getBankAccounts()).called(1);
    });
  });

  group('ConnectBankUseCase', () {
    late ConnectBankUseCase useCase;
    setUp(() => useCase = ConnectBankUseCase(mockRepo));

    test('retorna mapa con connectionId y authUrl', () async {
      final tResult = <String, dynamic>{
        'connectionId': 'conn-1',
        'authUrl': 'https://auth.bank.url',
      };
      when(
        mockRepo.connectBank('inst-santander'),
      ).thenAnswer((_) async => tResult);

      final result = await useCase('inst-santander');

      expect(result['connectionId'], 'conn-1');
      verify(mockRepo.connectBank('inst-santander')).called(1);
    });
  });

  group('DisconnectBankUseCase', () {
    late DisconnectBankUseCase useCase;
    setUp(() => useCase = DisconnectBankUseCase(mockRepo));

    test('delega al repositorio con el connectionId correcto', () async {
      when(mockRepo.disconnectBank('conn-1')).thenAnswer((_) async {
        return;
      });

      await useCase('conn-1');

      verify(mockRepo.disconnectBank('conn-1')).called(1);
    });
  });

  group('SyncBankUseCase', () {
    late SyncBankUseCase useCase;
    setUp(() => useCase = SyncBankUseCase(mockRepo));

    test('retorna cuentas actualizadas tras la sincronización', () async {
      when(mockRepo.syncBank('conn-1')).thenAnswer((_) async => [tAccount]);

      final result = await useCase('conn-1');

      expect(result.first.balanceCents, 150050);
      verify(mockRepo.syncBank('conn-1')).called(1);
    });
  });

  group('GetBankCardsUseCase', () {
    late GetBankCardsUseCase useCase;
    setUp(() => useCase = GetBankCardsUseCase(mockRepo));

    test('retorna lista de tarjetas', () async {
      when(mockRepo.getBankCards()).thenAnswer((_) async => [tCard]);

      final result = await useCase();

      expect(result.first.id, 'card-1');
    });
  });

  group('DeleteBankCardUseCase', () {
    late DeleteBankCardUseCase useCase;
    setUp(() => useCase = DeleteBankCardUseCase(mockRepo));

    test('delega con el cardId correcto', () async {
      when(mockRepo.deleteBankCard('card-1')).thenAnswer((_) async {
        return;
      });

      await useCase('card-1');

      verify(mockRepo.deleteBankCard('card-1')).called(1);
    });
  });

  group('ImportCsvUseCase', () {
    late ImportCsvUseCase useCase;
    setUp(() => useCase = ImportCsvUseCase(mockRepo));

    test('retorna mapa con imported y skipped', () async {
      final tRows = [
        <String, String>{'date': '2024-01-01', 'amount': '-50'},
      ];
      // Corregimos el mapa para que coincida con la expectativa (imported)
      final tResult = <String, int>{'imported': 5, 'skipped': 0};

      when(
        mockRepo.importCsvTransactions(bankAccountId: 'acc-1', rows: tRows),
      ).thenAnswer((_) async => tResult);

      final result = await useCase(bankAccountId: 'acc-1', rows: tRows);

      expect(result['imported'], 5);
      verify(
        mockRepo.importCsvTransactions(bankAccountId: 'acc-1', rows: tRows),
      ).called(1);
    });
  });

  group('BankAccountEntity getters', () {
    test('balance convierte cents a euros', () {
      expect(tAccount.balance, closeTo(1500.50, 0.001));
    });

    test('maskedIban con IBAN completo muestra los 4 últimos', () {
      const acc = BankAccountEntity(
        id: 'x',
        connectionId: 'c',
        accountName: 'Test',
        balanceCents: 0,
        iban: 'ES9121000418450200051332',
      );
      expect(acc.maskedIban, contains('1332'));
    });
  });
}
