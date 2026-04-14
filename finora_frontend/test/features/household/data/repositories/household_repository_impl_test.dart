import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/household/data/datasources/household_remote_datasource.dart';
import 'package:finora_frontend/features/household/data/models/household_model.dart';
import 'package:finora_frontend/features/household/data/repositories/household_repository_impl.dart';
import 'package:finora_frontend/features/household/domain/entities/household_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/household_member_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/shared_transaction_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/balance_entity.dart';

// Importamos el archivo que se generará
import 'household_repository_impl_test.mocks.dart';

@GenerateMocks([HouseholdRemoteDataSource])
void main() {
  late MockHouseholdRemoteDataSource mockDs;
  late HouseholdRepositoryImpl repository;

  final tHousehold = HouseholdModel.fromJson(<String, dynamic>{
    'id': 'hh-1',
    'name': 'Mi Hogar',
    'owner_id': 'user-1',
    'created_at': '2024-01-01T00:00:00.000Z',
  });

  final tMember = HouseholdMemberModel.fromJson(<String, dynamic>{
    'id': 'mem-1',
    'user_id': 'user-2',
    'role': 'member',
    'joined_at': '2024-02-01T00:00:00.000Z',
  });

  final tTransaction = SharedTransactionModel.fromJson(<String, dynamic>{
    'id': 'st-1',
    'amount': 100.0,
    'description': 'Cena',
    'created_at': '2024-03-01T00:00:00.000Z',
    'splits': [],
  });

  final tBalance = BalanceModel.fromJson(<String, dynamic>{
    'payer_id': 'user-1',
    'ower_id': 'user-2',
    'amount': 25.0,
  });

  setUp(() {
    mockDs = MockHouseholdRemoteDataSource();
    repository = HouseholdRepositoryImpl(mockDs);
  });

  // ── getHousehold ──────────────────────────────────────────────────────────
  group('getHousehold', () {
    test('retorna HouseholdEntity cuando existe', () async {
      when(mockDs.getHousehold()).thenAnswer((_) async => tHousehold);

      final result = await repository.getHousehold();

      expect(result, isA<HouseholdEntity>());
      expect(result!.id, 'hh-1');
      verify(mockDs.getHousehold()).called(1);
    });

    test('retorna null cuando no hay hogar', () async {
      when(mockDs.getHousehold()).thenAnswer((_) async => null);

      final result = await repository.getHousehold();
      expect(result, isNull);
    });
  });

  // ── createHousehold ───────────────────────────────────────────────────────
  group('createHousehold', () {
    test('retorna HouseholdEntity con el nombre correcto', () async {
      when(
        mockDs.createHousehold('Mi Hogar'),
      ).thenAnswer((_) async => tHousehold);

      final result = await repository.createHousehold('Mi Hogar');

      expect(result, isA<HouseholdEntity>());
      verify(mockDs.createHousehold('Mi Hogar')).called(1);
    });
  });

  // ── deleteHousehold ───────────────────────────────────────────────────────
  group('deleteHousehold', () {
    test('delega al datasource', () async {
      when(mockDs.deleteHousehold()).thenAnswer((_) async {
        return;
      });

      await repository.deleteHousehold();

      verify(mockDs.deleteHousehold()).called(1);
    });
  });

  // ── inviteMember ──────────────────────────────────────────────────────────
  group('inviteMember', () {
    test('delega con el email correcto', () async {
      when(mockDs.inviteMember('ana@example.com')).thenAnswer((_) async {
        return;
      });

      await repository.inviteMember('ana@example.com');

      verify(mockDs.inviteMember('ana@example.com')).called(1);
    });
  });

  // ── removeMember ──────────────────────────────────────────────────────────
  group('removeMember', () {
    test('delega con el userId correcto', () async {
      when(mockDs.removeMember('user-2')).thenAnswer((_) async {
        return;
      });

      await repository.removeMember('user-2');

      verify(mockDs.removeMember('user-2')).called(1);
    });
  });

  // ── getMembers ────────────────────────────────────────────────────────────
  group('getMembers', () {
    test('retorna lista de HouseholdMemberEntity', () async {
      when(mockDs.getMembers()).thenAnswer((_) async => [tMember]);

      final result = await repository.getMembers();

      expect(result, isA<List<HouseholdMemberEntity>>());
      expect(result.first.userId, 'user-2');
    });
  });

  // ── createSharedTransaction ───────────────────────────────────────────────
  group('createSharedTransaction', () {
    test('delega con los datos correctos', () async {
      final data = <String, dynamic>{'amount': 50.0, 'description': 'Pizza'};
      when(mockDs.createSharedTransaction(data)).thenAnswer((_) async {
        return;
      });

      await repository.createSharedTransaction(data);

      verify(mockDs.createSharedTransaction(data)).called(1);
    });
  });

  // ── getSharedTransactions ─────────────────────────────────────────────────
  group('getSharedTransactions', () {
    test('retorna lista de SharedTransactionEntity', () async {
      when(
        mockDs.getSharedTransactions(),
      ).thenAnswer((_) async => [tTransaction]);

      final result = await repository.getSharedTransactions();

      expect(result, isA<List<SharedTransactionEntity>>());
      expect(result.first.description, 'Cena');
    });
  });

  // ── getBalances ───────────────────────────────────────────────────────────
  group('getBalances', () {
    test('retorna lista de BalanceEntity', () async {
      when(mockDs.getBalances()).thenAnswer((_) async => [tBalance]);

      final result = await repository.getBalances();

      expect(result, isA<List<BalanceEntity>>());
      expect(result.first.amount, 25.0);
    });
  });

  // ── settleBalance ─────────────────────────────────────────────────────────
  group('settleBalance', () {
    test('delega con withUserId correcto', () async {
      when(mockDs.settleBalance('user-2')).thenAnswer((_) async {
        return;
      });

      await repository.settleBalance('user-2');

      verify(mockDs.settleBalance('user-2')).called(1);
    });
  });
}
