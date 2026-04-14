import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
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

@GenerateMocks([InvestmentsRepository])
import 'investment_usecases_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helper factories
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 4, 9);

InvestorProfileEntity makeProfile({
  String id = 'profile-1',
  String riskTolerance = 'moderate',
  String investmentHorizon = 'medium',
}) =>
    InvestorProfileEntity(
      id: id,
      riskTolerance: riskTolerance,
      investmentHorizon: investmentHorizon,
      monthlyCapacity: 500.0,
      createdAt: _now,
      updatedAt: _now,
    );

PortfolioSuggestionEntity makePortfolioSuggestion({
  String riskTolerance = 'moderate',
}) =>
    PortfolioSuggestionEntity(
      riskTolerance: riskTolerance,
      portfolio: const [
        PortfolioAllocationEntity(
          etf: 'Vanguard S&P 500',
          ticker: 'VOO',
          allocation: 60,
          category: 'equity',
        ),
      ],
      rationale: 'Balanced moderate portfolio',
    );

MarketIndexEntity makeIndex({String ticker = 'SPX'}) => MarketIndexEntity(
      name: 'S&P 500',
      ticker: ticker,
      value: 5200.0,
      change: 0.85,
      currency: 'USD',
      category: 'equity',
    );

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late MockInvestmentsRepository mockRepository;

  setUp(() {
    mockRepository = MockInvestmentsRepository();
  });

  // ── GetProfileUseCase ───────────────────────────────────────────────────────

  group('GetProfileUseCase', () {
    late GetProfileUseCase useCase;
    setUp(() => useCase = GetProfileUseCase(mockRepository));

    test('returns InvestorProfileEntity when profile exists', () async {
      final profile = makeProfile();
      when(mockRepository.getProfile()).thenAnswer((_) async => profile);

      final result = await useCase();

      expect(result, isNotNull);
      expect(result!.riskTolerance, 'moderate');
      expect(result.investmentHorizon, 'medium');
      verify(mockRepository.getProfile()).called(1);
    });

    test('returns null when no profile yet', () async {
      when(mockRepository.getProfile()).thenAnswer((_) async => null);

      final result = await useCase();

      expect(result, isNull);
    });

    test('returns profile with conservative risk tolerance', () async {
      final profile = makeProfile(riskTolerance: 'conservative');
      when(mockRepository.getProfile()).thenAnswer((_) async => profile);

      final result = await useCase();

      expect(result?.riskTolerance, 'conservative');
    });

    test('propagates exception from repository', () async {
      when(mockRepository.getProfile()).thenThrow(Exception('Profile fetch failed'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── SaveProfileUseCase ──────────────────────────────────────────────────────

  group('SaveProfileUseCase', () {
    late SaveProfileUseCase useCase;
    setUp(() => useCase = SaveProfileUseCase(mockRepository));

    final profileData = <String, dynamic>{
      'risk_tolerance': 'aggressive',
      'investment_horizon': 'long',
      'monthly_capacity': 1000.0,
    };

    test('returns saved InvestorProfileEntity on success', () async {
      final savedProfile = makeProfile(
        riskTolerance: 'aggressive',
        investmentHorizon: 'long',
      );
      when(mockRepository.saveProfile(any)).thenAnswer((_) async => savedProfile);

      final result = await useCase(profileData);

      expect(result.riskTolerance, 'aggressive');
      expect(result.investmentHorizon, 'long');
      verify(mockRepository.saveProfile(profileData)).called(1);
    });

    test('passes data map to repository unmodified', () async {
      final savedProfile = makeProfile();
      when(mockRepository.saveProfile(any)).thenAnswer((_) async => savedProfile);

      await useCase(profileData);

      final captured = verify(mockRepository.saveProfile(captureAny)).captured;
      expect(captured.first, profileData);
    });

    test('propagates exception from repository', () async {
      when(mockRepository.saveProfile(any))
          .thenThrow(Exception('Validation failed'));

      expect(() => useCase(profileData), throwsException);
    });
  });

  // ── GetPortfolioSuggestionUseCase ───────────────────────────────────────────

  group('GetPortfolioSuggestionUseCase', () {
    late GetPortfolioSuggestionUseCase useCase;
    setUp(() => useCase = GetPortfolioSuggestionUseCase(mockRepository));

    test('returns PortfolioSuggestionEntity on success', () async {
      final suggestion = makePortfolioSuggestion();
      when(mockRepository.getPortfolioSuggestion())
          .thenAnswer((_) async => suggestion);

      final result = await useCase();

      expect(result.riskTolerance, 'moderate');
      expect(result.portfolio, hasLength(1));
      expect(result.portfolio.first.ticker, 'VOO');
      verify(mockRepository.getPortfolioSuggestion()).called(1);
    });

    test('returns aggressive portfolio suggestion', () async {
      final suggestion = makePortfolioSuggestion(riskTolerance: 'aggressive');
      when(mockRepository.getPortfolioSuggestion())
          .thenAnswer((_) async => suggestion);

      final result = await useCase();

      expect(result.riskTolerance, 'aggressive');
    });

    test('returns portfolio with rationale', () async {
      final suggestion = makePortfolioSuggestion();
      when(mockRepository.getPortfolioSuggestion())
          .thenAnswer((_) async => suggestion);

      final result = await useCase();

      expect(result.rationale, isNotEmpty);
    });

    test('propagates exception from repository', () async {
      when(mockRepository.getPortfolioSuggestion())
          .thenThrow(Exception('AI service unavailable'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── SimulateReturnsUseCase ──────────────────────────────────────────────────

  group('SimulateReturnsUseCase', () {
    late SimulateReturnsUseCase useCase;
    setUp(() => useCase = SimulateReturnsUseCase(mockRepository));

    final simulationInput = <String, dynamic>{
      'monthly_contribution': 500.0,
      'years': 10,
      'risk_tolerance': 'moderate',
    };

    final simulationResult = <String, dynamic>{
      'total_invested': 60000.0,
      'estimated_return': 85000.0,
      'annual_rate': 7.0,
    };

    test('returns simulation result map on success', () async {
      when(mockRepository.simulateReturns(any))
          .thenAnswer((_) async => simulationResult);

      final result = await useCase(simulationInput);

      expect(result['total_invested'], 60000.0);
      expect(result['estimated_return'], 85000.0);
      expect(result['annual_rate'], 7.0);
      verify(mockRepository.simulateReturns(simulationInput)).called(1);
    });

    test('passes data map to repository unmodified', () async {
      when(mockRepository.simulateReturns(any))
          .thenAnswer((_) async => simulationResult);

      await useCase(simulationInput);

      final captured =
          verify(mockRepository.simulateReturns(captureAny)).captured;
      expect(captured.first, simulationInput);
    });

    test('handles conservative simulation returning lower returns', () async {
      final conservativeResult = <String, dynamic>{
        'total_invested': 60000.0,
        'estimated_return': 70000.0,
        'annual_rate': 4.0,
      };
      when(mockRepository.simulateReturns(any))
          .thenAnswer((_) async => conservativeResult);

      final result = await useCase({
        'monthly_contribution': 500.0,
        'years': 10,
        'risk_tolerance': 'conservative',
      });

      expect(result['annual_rate'], 4.0);
    });

    test('propagates exception from repository', () async {
      when(mockRepository.simulateReturns(any))
          .thenThrow(Exception('Simulation failed'));

      expect(() => useCase(simulationInput), throwsException);
    });
  });

  // ── GetIndicesUseCase ───────────────────────────────────────────────────────

  group('GetIndicesUseCase', () {
    late GetIndicesUseCase useCase;
    setUp(() => useCase = GetIndicesUseCase(mockRepository));

    test('returns list of MarketIndexEntity on success', () async {
      final indices = [makeIndex(), makeIndex(ticker: 'DAX')];
      when(mockRepository.getIndices()).thenAnswer((_) async => indices);

      final result = await useCase();

      expect(result, hasLength(2));
      expect(result.first.ticker, 'SPX');
      expect(result.first.value, 5200.0);
      verify(mockRepository.getIndices()).called(1);
    });

    test('returns empty list when no indices available', () async {
      when(mockRepository.getIndices()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('returns index with correct change value', () async {
      final indices = [makeIndex()];
      when(mockRepository.getIndices()).thenAnswer((_) async => indices);

      final result = await useCase();

      expect(result.first.change, 0.85);
      expect(result.first.isPositive, isTrue);
    });

    test('propagates exception from repository', () async {
      when(mockRepository.getIndices())
          .thenThrow(Exception('Market data unavailable'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── GetGlossaryUseCase ──────────────────────────────────────────────────────

  group('GetGlossaryUseCase', () {
    late GetGlossaryUseCase useCase;
    setUp(() => useCase = GetGlossaryUseCase(mockRepository));

    final glossaryTerms = [
      {'term': 'ETF', 'definition': 'Exchange-Traded Fund'},
      {'term': 'Diversification', 'definition': 'Spreading risk across assets'},
      {'term': 'Rebalancing', 'definition': 'Adjusting portfolio allocations'},
    ];

    test('returns list of glossary terms on success', () async {
      when(mockRepository.getGlossary()).thenAnswer((_) async => glossaryTerms);

      final result = await useCase();

      expect(result, hasLength(3));
      expect(result.first['term'], 'ETF');
      expect(result.first['definition'], 'Exchange-Traded Fund');
      verify(mockRepository.getGlossary()).called(1);
    });

    test('returns empty list when glossary is empty', () async {
      when(mockRepository.getGlossary()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('returns glossary with all expected keys', () async {
      when(mockRepository.getGlossary()).thenAnswer((_) async => glossaryTerms);

      final result = await useCase();

      for (final term in result) {
        expect(term.containsKey('term'), isTrue);
        expect(term.containsKey('definition'), isTrue);
      }
    });

    test('propagates exception from repository', () async {
      when(mockRepository.getGlossary())
          .thenThrow(Exception('Glossary fetch failed'));

      expect(() => useCase(), throwsException);
    });
  });
}

