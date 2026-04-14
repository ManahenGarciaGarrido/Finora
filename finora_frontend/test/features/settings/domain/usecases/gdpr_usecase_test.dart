import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/errors/failures.dart';
import 'package:finora_frontend/core/usecases/usecase.dart';
import 'package:finora_frontend/features/settings/domain/entities/consent.dart';
import 'package:finora_frontend/features/settings/domain/repositories/gdpr_repository.dart';
import 'package:finora_frontend/features/settings/domain/usecases/manage_consents_usecase.dart';
import 'package:finora_frontend/features/settings/domain/usecases/delete_account_usecase.dart';
import 'package:finora_frontend/features/settings/domain/entities/user_data_export.dart';

// Importamos los mocks generados
import 'gdpr_usecase_test.mocks.dart';

@GenerateMocks([GDPRRepository])
void main() {
  late MockGDPRRepository mockRepo;

  final tConsents = UserConsents(
    userId: 'user-1',
    consents: {ConsentType.essential: true, ConsentType.analytics: false},
    lastUpdated: DateTime(2024, 6, 1),
  );

  setUp(() => mockRepo = MockGDPRRepository());

  // ── GetUserConsentsUseCase ────────────────────────────────────────────────────
  group('GetUserConsentsUseCase', () {
    late GetUserConsentsUseCase useCase;
    setUp(() => useCase = GetUserConsentsUseCase(mockRepo));

    test('retorna Right(UserConsents) del repositorio', () async {
      when(
        mockRepo.getUserConsents(),
      ).thenAnswer((_) async => Right(tConsents));

      final result = await useCase(const NoParams());

      expect(result.isRight(), true);
      result.fold((_) => fail('Right'), (c) => expect(c.userId, 'user-1'));
      verify(mockRepo.getUserConsents()).called(1);
    });

    test('propaga Left(NetworkFailure) del repositorio', () async {
      when(mockRepo.getUserConsents()).thenAnswer(
        (_) async =>
            const Left(NetworkFailure(message: 'No internet connection')),
      );

      final result = await useCase(const NoParams());

      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('Left'));
    });
  });

  // ── UpdateConsentsUseCase ─────────────────────────────────────────────────────
  group('UpdateConsentsUseCase', () {
    late UpdateConsentsUseCase useCase;
    setUp(() => useCase = UpdateConsentsUseCase(mockRepo));

    test('llama al repositorio con los consentimientos correctos', () async {
      final consents = <ConsentType, bool>{
        ConsentType.analytics: true,
        ConsentType.marketing: false,
      };

      when(
        mockRepo.updateConsents(consents),
      ).thenAnswer((_) async => Right(tConsents));

      final result = await useCase(UpdateConsentsParams(consents: consents));

      expect(result.isRight(), true);
      verify(mockRepo.updateConsents(consents)).called(1);
    });
  });

  // ── WithdrawConsentUseCase ────────────────────────────────────────────────────
  group('WithdrawConsentUseCase', () {
    late WithdrawConsentUseCase useCase;
    setUp(() => useCase = WithdrawConsentUseCase(mockRepo));

    test(
      'llama al repositorio con el tipo de consentimiento correcto',
      () async {
        when(
          mockRepo.withdrawConsent(ConsentType.marketing),
        ).thenAnswer((_) async => Right(tConsents));

        final result = await useCase(
          const WithdrawConsentParams(consentType: ConsentType.marketing),
        );

        expect(result.isRight(), true);
        verify(mockRepo.withdrawConsent(ConsentType.marketing)).called(1);
      },
    );
  });

  // ── GetConsentHistoryUseCase ──────────────────────────────────────────────────
  group('GetConsentHistoryUseCase', () {
    late GetConsentHistoryUseCase useCase;
    setUp(() => useCase = GetConsentHistoryUseCase(mockRepo));

    test('retorna Right(List<ConsentHistoryEntry>) del repositorio', () async {
      final tHistory = [
        ConsentHistoryEntry(
          timestamp: DateTime(2024, 5, 1),
          action: 'accepted',
        ),
      ];
      when(
        mockRepo.getConsentHistory(),
      ).thenAnswer((_) async => Right(tHistory));

      final result = await useCase(const NoParams());

      result.fold(
        (_) => fail('Right'),
        (h) => expect(h.first.action, 'accepted'),
      );
    });
  });

  // ── DeleteAccountUseCase ──────────────────────────────────────────────────────
  group('DeleteAccountUseCase', () {
    late DeleteAccountUseCase useCase;
    setUp(() => useCase = DeleteAccountUseCase(mockRepo));

    AccountDeletionReceipt tReceipt() => AccountDeletionReceipt(
      receiptId: 'DEL-123',
      userId: 'user-1',
      deletionDate: DateTime(2024, 6, 1),
      dataDeleted: const ['transactions', 'goals'],
      retainedForLegal: const [],
      gdprCompliance: const GDPRComplianceInfo(
        article: 'Art. 17 GDPR',
        processingTime: '30 days',
        backupDeletion: '90 days',
      ),
    );

    test('llama al repositorio con la razón proporcionada', () async {
      when(
        mockRepo.deleteAccount(reason: 'No longer needed'),
      ).thenAnswer((_) async => Right(tReceipt()));

      final result = await useCase(
        const DeleteAccountParams(reason: 'No longer needed'),
      );

      expect(result.isRight(), true);
      verify(mockRepo.deleteAccount(reason: 'No longer needed')).called(1);
    });

    test('llama al repositorio sin razón cuando reason es null', () async {
      when(
        mockRepo.deleteAccount(reason: null),
      ).thenAnswer((_) async => Right(tReceipt()));

      await useCase(const DeleteAccountParams());

      verify(mockRepo.deleteAccount(reason: null)).called(1);
    });

    test('propaga Left(ServerFailure) del repositorio', () async {
      when(mockRepo.deleteAccount(reason: anyNamed('reason'))).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Deletion failed')),
      );

      final result = await useCase(const DeleteAccountParams());

      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('Left'));
    });
  });

  // ── UpdateConsentsParams Equatable ────────────────────────────────────────────
  group('Params Equatable', () {
    test('UpdateConsentsParams es igual cuando consents son iguales', () {
      final p1 = UpdateConsentsParams(consents: {ConsentType.analytics: true});
      final p2 = UpdateConsentsParams(consents: {ConsentType.analytics: true});
      expect(p1, equals(p2));
    });

    test('WithdrawConsentParams es igual cuando consentType es igual', () {
      const p1 = WithdrawConsentParams(consentType: ConsentType.marketing);
      const p2 = WithdrawConsentParams(consentType: ConsentType.marketing);
      expect(p1, equals(p2));
    });
  });
}
