import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:finora_frontend/core/network/network_info.dart';
import 'package:finora_frontend/features/settings/data/datasources/gdpr_remote_datasource.dart';
import 'package:finora_frontend/features/settings/data/models/consent_model.dart';
import 'package:finora_frontend/features/settings/data/repositories/gdpr_repository_impl.dart';
import 'package:finora_frontend/features/settings/domain/entities/consent.dart';

import 'gdpr_repository_impl_test.mocks.dart';

@GenerateMocks([GDPRRemoteDataSource, NetworkInfo])
void main() {
  late MockGDPRRemoteDataSource mockDs;
  late MockNetworkInfo mockNetwork;
  late GDPRRepositoryImpl repository;

  final tConsentsModel = UserConsentsModel(
    userId: 'user-1',
    consents: <ConsentType, bool>{
      ConsentType.essential: true,
      ConsentType.analytics: false,
    },
    lastUpdated: DateTime(2024, 6, 1),
  );

  setUp(() {
    mockDs = MockGDPRRemoteDataSource();
    mockNetwork = MockNetworkInfo();
    repository = GDPRRepositoryImpl(
      remoteDataSource: mockDs,
      networkInfo: mockNetwork,
    );
  });

  group('updateConsents', () {
    final tConsents = <ConsentType, bool>{
      ConsentType.analytics: true,
      ConsentType.marketing: false,
    };

    test(
      'retorna Right(UserConsents) con los consentimientos actualizados',
      () async {
        when(mockNetwork.isConnected).thenAnswer((_) async => true);
        when(
          mockDs.updateConsents(tConsents),
        ).thenAnswer((_) async => tConsentsModel);

        final result = await repository.updateConsents(tConsents);

        expect(result.isRight(), true);
        verify(mockDs.updateConsents(tConsents)).called(1);
      },
    );
  });
}
