import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/investments/domain/entities/investor_profile_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/portfolio_suggestion_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/market_index_entity.dart';
import 'package:finora_frontend/features/investments/domain/repositories/investments_repository.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_profile_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/save_profile_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_portfolio_suggestion_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/simulate_returns_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_indices_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_glossary_usecase.dart';

// Importamos los mocks que generará build_runner
import 'investments_usecase_test.mocks.dart';

@GenerateMocks([InvestmentsRepository])
void main() {
  late MockInvestmentsRepository mockRepo;

  final tProfileEntity = InvestorProfileEntity(
    id: 'prof-1',
    riskTolerance: 'moderate',
    investmentHorizon: '10_years',
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 6, 1),
  );

  const tSuggestion = PortfolioSuggestionEntity(
    riskTolerance: 'moderate',
    portfolio: [],
  );

  const tIndex = MarketIndexEntity(
    name: 'IBEX 35',
    ticker: 'IBEX',
    value: 10250.0,
    change: 1.2,
    currency: 'EUR',
  );

  setUp(() => mockRepo = MockInvestmentsRepository());

  // ── GetProfileUseCase ─────────────────────────────────────────────────────
  group('GetProfileUseCase', () {
    late GetProfileUseCase useCase;
    setUp(() => useCase = GetProfileUseCase(mockRepo));

    test('retorna InvestorProfileEntity del repositorio', () async {
      when(mockRepo.getProfile()).thenAnswer((_) async => tProfileEntity);

      final result = await useCase();

      expect(result, isA<InvestorProfileEntity>());
      expect(result!.riskTolerance, 'moderate');
      verify(mockRepo.getProfile()).called(1);
    });

    test('retorna null cuando no hay perfil guardado', () async {
      when(mockRepo.getProfile()).thenAnswer((_) async => null);

      final result = await useCase();
      expect(result, isNull);
    });
  });

  // ── SaveProfileUseCase ────────────────────────────────────────────────────
  group('SaveProfileUseCase', () {
    late SaveProfileUseCase useCase;
    setUp(() => useCase = SaveProfileUseCase(mockRepo));

    test('llama al repositorio con los datos correctos', () async {
      final data = <String, dynamic>{
        'risk_tolerance': 'aggressive',
        'investment_horizon': '20_years',
      };
      when(mockRepo.saveProfile(data)).thenAnswer((_) async => tProfileEntity);

      final result = await useCase(data);

      expect(result, isA<InvestorProfileEntity>());
      verify(mockRepo.saveProfile(data)).called(1);
    });
  });

  // ── GetPortfolioSuggestionUseCase ─────────────────────────────────────────
  group('GetPortfolioSuggestionUseCase', () {
    late GetPortfolioSuggestionUseCase useCase;
    setUp(() => useCase = GetPortfolioSuggestionUseCase(mockRepo));

    test('retorna PortfolioSuggestionEntity del repositorio', () async {
      when(
        mockRepo.getPortfolioSuggestion(),
      ).thenAnswer((_) async => tSuggestion);

      final result = await useCase();

      expect(result, isA<PortfolioSuggestionEntity>());
      verify(mockRepo.getPortfolioSuggestion()).called(1);
    });
  });

  // ── SimulateReturnsUseCase ────────────────────────────────────────────────
  group('SimulateReturnsUseCase', () {
    late SimulateReturnsUseCase useCase;
    setUp(() => useCase = SimulateReturnsUseCase(mockRepo));

    test('retorna mapa con resultados de simulación', () async {
      final tResult = <String, dynamic>{'final_value': 45000.0};
      final requestData = <String, dynamic>{
        'initial_amount': 10000,
        'years': 10,
      };

      when(
        mockRepo.simulateReturns(requestData),
      ).thenAnswer((_) async => tResult);

      final result = await useCase(requestData);

      expect(result['final_value'], 45000.0);
      verify(mockRepo.simulateReturns(requestData)).called(1);
    });
  });

  // ── GetIndicesUseCase ─────────────────────────────────────────────────────
  group('GetIndicesUseCase', () {
    late GetIndicesUseCase useCase;
    setUp(() => useCase = GetIndicesUseCase(mockRepo));

    test('retorna lista de MarketIndexEntity', () async {
      when(mockRepo.getIndices()).thenAnswer((_) async => [tIndex]);

      final result = await useCase();

      expect(result.first.name, 'IBEX 35');
      verify(mockRepo.getIndices()).called(1);
    });

    test('retorna lista vacía cuando no hay índices', () async {
      when(mockRepo.getIndices()).thenAnswer((_) async => []);

      final result = await useCase();
      expect(result, isEmpty);
    });
  });

  // ── GetGlossaryUseCase ────────────────────────────────────────────────────
  group('GetGlossaryUseCase', () {
    late GetGlossaryUseCase useCase;
    setUp(() => useCase = GetGlossaryUseCase(mockRepo));

    test('retorna lista de términos del glosario', () async {
      final tGlossary = [
        <String, String>{'term': 'ETF', 'definition': 'Exchange-Traded Fund'},
        <String, String>{'term': 'ROI', 'definition': 'Return on Investment'},
      ];
      when(mockRepo.getGlossary()).thenAnswer((_) async => tGlossary);

      final result = await useCase();

      expect(result.length, 2);
      expect(result.first['term'], 'ETF');
      verify(mockRepo.getGlossary()).called(1);
    });
  });
}
