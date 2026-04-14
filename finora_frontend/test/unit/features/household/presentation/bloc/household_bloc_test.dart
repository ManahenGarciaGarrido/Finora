import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/household/presentation/bloc/household_bloc.dart';
import 'package:finora_frontend/features/household/presentation/bloc/household_event.dart';
import 'package:finora_frontend/features/household/presentation/bloc/household_state.dart';
import 'package:finora_frontend/features/household/domain/repositories/household_repository.dart';
import 'package:finora_frontend/features/household/domain/entities/household_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/household_member_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/shared_transaction_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/balance_entity.dart';

@GenerateMocks([HouseholdRepository])
import 'household_bloc_test.mocks.dart';

void main() {
  late HouseholdBloc bloc;
  late MockHouseholdRepository mockRepo;

  final tHousehold = HouseholdEntity(
    id: 'hh-1',
    name: 'Casa García',
    ownerId: 'user-1',
    inviteCode: 'CASA2026',
    createdAt: DateTime(2026, 1, 1),
  );

  final tMember = HouseholdMemberEntity(
    id: 'member-1',
    userId: 'user-2',
    role: 'member',
    name: 'Ana García',
    email: 'ana@example.com',
    joinedAt: DateTime(2026, 2, 1),
  );

  final tSharedTx = SharedTransactionEntity(
    id: 'stx-1',
    amount: 50.0,
    description: 'Groceries',
    createdByName: 'Juan',
    createdAt: DateTime(2026, 4, 1),
    splits: [
      {'userId': 'user-1', 'amount': 25.0},
      {'userId': 'user-2', 'amount': 25.0},
    ],
  );

  final tBalance = BalanceEntity(
    payerId: 'user-1',
    owerId: 'user-2',
    amount: 25.0,
  );

  setUp(() {
    mockRepo = MockHouseholdRepository();
    bloc = HouseholdBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is HouseholdInitial', () {
    expect(bloc.state, isA<HouseholdInitial>());
  });

  group('LoadHousehold', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdLoaded] when household exists',
      build: () {
        when(mockRepo.getHousehold()).thenAnswer((_) async => tHousehold);
        return bloc;
      },
      act: (b) => b.add(const LoadHousehold()),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdLoaded>()],
      verify: (_) {
        verify(mockRepo.getHousehold()).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'HouseholdLoaded contains correct household data',
      build: () {
        when(mockRepo.getHousehold()).thenAnswer((_) async => tHousehold);
        return bloc;
      },
      act: (b) => b.add(const LoadHousehold()),
      expect: () => [
        isA<HouseholdLoading>(),
        predicate<HouseholdState>((s) {
          if (s is HouseholdLoaded) {
            return s.household?.name == 'Casa García' &&
                s.household?.id == 'hh-1';
          }
          return false;
        }),
      ],
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdLoaded(null)] when no household yet',
      build: () {
        when(mockRepo.getHousehold()).thenAnswer((_) async => null);
        return bloc;
      },
      act: (b) => b.add(const LoadHousehold()),
      expect: () => [
        isA<HouseholdLoading>(),
        predicate<HouseholdState>((s) {
          if (s is HouseholdLoaded) {
            return s.household == null;
          }
          return false;
        }),
      ],
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdError] on error',
      build: () {
        when(mockRepo.getHousehold()).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const LoadHousehold()),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdError>()],
    );
  });

  group('CreateHousehold', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdCreated] on success',
      build: () {
        when(
          mockRepo.createHousehold('Casa García'),
        ).thenAnswer((_) async => tHousehold);
        return bloc;
      },
      act: (b) => b.add(const CreateHousehold('Casa García')),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdCreated>()],
      verify: (_) {
        verify(mockRepo.createHousehold('Casa García')).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'HouseholdCreated contains the new household entity',
      build: () {
        when(mockRepo.createHousehold(any)).thenAnswer((_) async => tHousehold);
        return bloc;
      },
      act: (b) => b.add(const CreateHousehold('Casa García')),
      expect: () => [
        isA<HouseholdLoading>(),
        predicate<HouseholdState>((s) {
          if (s is HouseholdCreated) {
            return s.household.name == 'Casa García';
          }
          return false;
        }),
      ],
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdError] when name validation fails on server',
      build: () {
        when(
          mockRepo.createHousehold(any),
        ).thenThrow(Exception('Name too short'));
        return bloc;
      },
      act: (b) => b.add(const CreateHousehold('A')),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdError>()],
    );
  });

  group('InviteMember', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, MemberInvited] on success',
      build: () {
        when(mockRepo.inviteMember('ana@example.com')).thenAnswer((_) async {
          return;
        });
        return bloc;
      },
      act: (b) => b.add(const InviteMember('ana@example.com')),
      expect: () => [isA<HouseholdLoading>(), isA<MemberInvited>()],
      verify: (_) {
        verify(mockRepo.inviteMember('ana@example.com')).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdError] when already a member',
      build: () {
        when(
          mockRepo.inviteMember(any),
        ).thenThrow(Exception('User is already a member'));
        return bloc;
      },
      act: (b) => b.add(const InviteMember('existing@example.com')),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdError>()],
    );
  });

  group('RemoveMember', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, MembersLoaded] on success',
      build: () {
        when(mockRepo.removeMember('user-2')).thenAnswer((_) async {
          return;
        });
        when(mockRepo.getMembers()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const RemoveMember('user-2')),
      expect: () => [isA<HouseholdLoading>(), isA<MembersLoaded>()],
      verify: (_) {
        verify(mockRepo.removeMember('user-2')).called(1);
        verify(mockRepo.getMembers()).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdError] when remove fails',
      build: () {
        when(
          mockRepo.removeMember(any),
        ).thenThrow(Exception('Cannot remove owner'));
        return bloc;
      },
      act: (b) => b.add(const RemoveMember('user-1')),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdError>()],
    );
  });

  group('LoadMembers', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, MembersLoaded] with members',
      build: () {
        when(mockRepo.getMembers()).thenAnswer((_) async => [tMember]);
        return bloc;
      },
      act: (b) => b.add(const LoadMembers()),
      expect: () => [isA<HouseholdLoading>(), isA<MembersLoaded>()],
      verify: (_) {
        verify(mockRepo.getMembers()).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, MembersLoaded] with empty list',
      build: () {
        when(mockRepo.getMembers()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadMembers()),
      expect: () => [
        isA<HouseholdLoading>(),
        predicate<HouseholdState>((s) {
          if (s is MembersLoaded) {
            return s.members.isEmpty;
          }
          return false;
        }),
      ],
    );
  });

  group('LoadSharedTransactions', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, TransactionsLoaded] with transactions',
      build: () {
        when(
          mockRepo.getSharedTransactions(),
        ).thenAnswer((_) async => [tSharedTx]);
        return bloc;
      },
      act: (b) => b.add(const LoadSharedTransactions()),
      expect: () => [isA<HouseholdLoading>(), isA<TransactionsLoaded>()],
      verify: (_) {
        verify(mockRepo.getSharedTransactions()).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, TransactionsLoaded] with empty list',
      build: () {
        when(mockRepo.getSharedTransactions()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadSharedTransactions()),
      expect: () => [
        isA<HouseholdLoading>(),
        predicate<HouseholdState>((s) {
          if (s is TransactionsLoaded) {
            return s.transactions.isEmpty;
          }
          return false;
        }),
      ],
    );
  });

  group('CreateSharedTransaction', () {
    final txData = <String, dynamic>{
      'amount': 50.0,
      'description': 'Groceries',
      'splits': [
        {'userId': 'user-1', 'amount': 25.0},
        {'userId': 'user-2', 'amount': 25.0},
      ],
    };

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, TransactionsLoaded] on success',
      build: () {
        when(mockRepo.createSharedTransaction(txData)).thenAnswer((_) async {
          return;
        });
        when(
          mockRepo.getSharedTransactions(),
        ).thenAnswer((_) async => [tSharedTx]);
        return bloc;
      },
      act: (b) => b.add(CreateSharedTransaction(txData)),
      expect: () => [isA<HouseholdLoading>(), isA<TransactionsLoaded>()],
      verify: (_) {
        verify(mockRepo.createSharedTransaction(txData)).called(1);
        verify(mockRepo.getSharedTransactions()).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdError] when creation fails',
      build: () {
        when(
          mockRepo.createSharedTransaction(any),
        ).thenThrow(Exception('Invalid transaction data'));
        return bloc;
      },
      act: (b) => b.add(CreateSharedTransaction(txData)),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdError>()],
    );
  });

  group('LoadBalances', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, BalancesLoaded] with balances',
      build: () {
        when(mockRepo.getBalances()).thenAnswer((_) async => [tBalance]);
        return bloc;
      },
      act: (b) => b.add(const LoadBalances()),
      expect: () => [isA<HouseholdLoading>(), isA<BalancesLoaded>()],
      verify: (_) {
        verify(mockRepo.getBalances()).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'BalancesLoaded contains correct balance data',
      build: () {
        when(mockRepo.getBalances()).thenAnswer((_) async => [tBalance]);
        return bloc;
      },
      act: (b) => b.add(const LoadBalances()),
      expect: () => [
        isA<HouseholdLoading>(),
        predicate<HouseholdState>((s) {
          if (s is BalancesLoaded) {
            return s.balances.length == 1 && s.balances.first.amount == 25.0;
          }
          return false;
        }),
      ],
    );
  });

  group('SettleBalance', () {
    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, BalanceSettled] on success',
      build: () {
        when(mockRepo.settleBalance('user-2')).thenAnswer((_) async {
          return;
        });
        return bloc;
      },
      act: (b) => b.add(const SettleBalance('user-2')),
      expect: () => [isA<HouseholdLoading>(), isA<BalanceSettled>()],
      verify: (_) {
        verify(mockRepo.settleBalance('user-2')).called(1);
      },
    );

    blocTest<HouseholdBloc, HouseholdState>(
      'emits [HouseholdLoading, HouseholdError] when settle fails',
      build: () {
        when(
          mockRepo.settleBalance(any),
        ).thenThrow(Exception('No balance to settle'));
        return bloc;
      },
      act: (b) => b.add(const SettleBalance('user-2')),
      expect: () => [isA<HouseholdLoading>(), isA<HouseholdError>()],
    );
  });
}

