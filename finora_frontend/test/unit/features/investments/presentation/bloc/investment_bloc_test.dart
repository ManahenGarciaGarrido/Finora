import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/investments/domain/entities/investor_profile_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/portfolio_suggestion_entity.dart';
import 'package:finora_frontend/features/investments/domain/entities/market_index_entity.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_profile_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/save_profile_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_portfolio_suggestion_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/simulate_returns_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_indices_usecase.dart';
import 'package:finora_frontend/features/investments/domain/usecases/get_glossary_usecase.dart';
import 'package:finora_frontend/features/investments/domain/repositories/investments_repository.dart';
import 'package:finora_frontend/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:finora_frontend/features/investments/presentation/bloc/investment_event.dart';
import 'package:finora_frontend/features/investments/presentation/bloc/investment_state.dart';

@GenerateMocks([
  GetProfileUseCase,
  SaveProfileUseCase,
  GetPortfolioSuggestionUseCase,
  SimulateReturnsUseCase,
  GetIndicesUseCase,
  GetGlossaryUseCase,
  InvestmentsRepository,
])
import 'investment_bloc_test.mocks.dart';

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

PortfolioSuggestionEntity makePortfolioSuggestion() =>
    const PortfolioSuggestionEntity(
      riskTolerance: 'moderate',
      portfolio: [
        PortfolioAllocationEntity(
          etf: 'Vanguard S&P 500',
          ticker: 'VOO',
          allocation: 60,
          category: 'equity',
        ),
        PortfolioAllocationEntity(
          etf: 'iShares Core US Aggregate',
          ticker: 'AGG',
          allocation: 40,
          category: 'bond',
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
      spark: const [5100.0, 5150.0, 5200.0],
    );

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late InvestmentBloc bloc;
  late MockGetProfileUseCase mockGetProfile;
  late MockSaveProfileUseCase mockSaveProfile;
  late MockGetPortfolioSuggestionUseCase mockGetPortfolioSuggestion;
  late MockSimulateReturnsUseCase mockSimulateReturns;
  late MockGetIndicesUseCase mockGetIndices;
  late MockGetGlossaryUseCase mockGetGlossary;
  late MockInvestmentsRepository mockRepository;

  setUp(() {
    mockGetProfile = MockGetProfileUseCase();
    mockSaveProfile = MockSaveProfileUseCase();
    mockGetPortfolioSuggestion = MockGetPortfolioSuggestionUseCase();
    mockSimulateReturns = MockSimulateReturnsUseCase();
    mockGetIndices = MockGetIndicesUseCase();
    mockGetGlossary = MockGetGlossaryUseCase();
    mockRepository = MockInvestmentsRepository();

    bloc = InvestmentBloc(
      getProfile: mockGetProfile,
      saveProfile: mockSaveProfile,
      getPortfolioSuggestion: mockGetPortfolioSuggestion,
      simulateReturns: mockSimulateReturns,
      getIndices: mockGetIndices,
      getGlossary: mockGetGlossary,
      repository: mockRepository,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is InvestmentInitial', () {
    expect(bloc.state, isA<InvestmentInitial>());
  });

  // ── LoadProfile ─────────────────────────────────────────────────────────────

  group('LoadProfile', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, ProfileLoaded] when profile exists',
      build: () {
        when(mockGetProfile()).thenAnswer((_) async => makeProfile());
        return bloc;
      },
      act: (b) => b.add(const LoadProfile()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<ProfileLoaded>().having(
          (s) => s.profile?.riskTolerance,
          'riskTolerance',
          'moderate',
        ),
      ],
      verify: (_) => verify(mockGetProfile()).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, ProfileLoaded] with null when no profile yet',
      build: () {
        when(mockGetProfile()).thenAnswer((_) async => null);
        return bloc;
      },
      act: (b) => b.add(const LoadProfile()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<ProfileLoaded>().having((s) => s.profile, 'profile', isNull),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on exception',
      build: () {
        when(mockGetProfile()).thenThrow(Exception('Server error'));
        return bloc;
      },
      act: (b) => b.add(const LoadProfile()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<InvestmentError>(),
      ],
    );
  });

  // ── SaveProfile ─────────────────────────────────────────────────────────────

  group('SaveProfile', () {
    final profileData = <String, dynamic>{
      'risk_tolerance': 'aggressive',
      'investment_horizon': 'long',
      'monthly_capacity': 1000.0,
    };

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, ProfileSaved] on success',
      build: () {
        final savedProfile = makeProfile(
          riskTolerance: 'aggressive',
          investmentHorizon: 'long',
        );
        when(mockSaveProfile(any)).thenAnswer((_) async => savedProfile);
        return bloc;
      },
      act: (b) => b.add(SaveProfile(profileData)),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<ProfileSaved>().having(
          (s) => s.profile.riskTolerance,
          'riskTolerance',
          'aggressive',
        ),
      ],
      verify: (_) => verify(mockSaveProfile(profileData)).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on exception',
      build: () {
        when(mockSaveProfile(any)).thenThrow(Exception('Validation failed'));
        return bloc;
      },
      act: (b) => b.add(SaveProfile(profileData)),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<InvestmentError>().having(
          (s) => s.message,
          'message',
          contains('Validation failed'),
        ),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'strips "Exception: " prefix from error message',
      build: () {
        when(mockSaveProfile(any)).thenThrow(Exception('Save failed'));
        return bloc;
      },
      act: (b) => b.add(SaveProfile(profileData)),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<InvestmentError>().having(
          (s) => s.message,
          'message',
          isNot(contains('Exception:')),
        ),
      ],
    );
  });

  // ── LoadPortfolioSuggestion ─────────────────────────────────────────────────

  group('LoadPortfolioSuggestion', () {
    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, PortfolioLoaded] on success',
      build: () {
        when(mockGetPortfolioSuggestion())
            .thenAnswer((_) async => makePortfolioSuggestion());
        return bloc;
      },
      act: (b) => b.add(const LoadPortfolioSuggestion()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<PortfolioLoaded>().having(
          (s) => s.suggestion.riskTolerance,
          'riskTolerance',
          'moderate',
        ),
      ],
      verify: (_) => verify(mockGetPortfolioSuggestion()).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, PortfolioLoaded] with correct portfolio allocations',
      build: () {
        when(mockGetPortfolioSuggestion())
            .thenAnswer((_) async => makePortfolioSuggestion());
        return bloc;
      },
      act: (b) => b.add(const LoadPortfolioSuggestion()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<PortfolioLoaded>().having(
          (s) => s.suggestion.portfolio.length,
          'portfolio length',
          2,
        ),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading] only (swallows error silently) on exception',
      build: () {
        when(mockGetPortfolioSuggestion()).thenThrow(Exception('AI error'));
        return bloc;
      },
      act: (b) => b.add(const LoadPortfolioSuggestion()),
      expect: () => [isA<InvestmentLoading>()],
    );
  });

  // ── SimulateReturns ─────────────────────────────────────────────────────────

  group('SimulateReturns', () {
    final simulationInput = <String, dynamic>{
      'monthly_contribution': 500.0,
      'years': 10,
      'risk_tolerance': 'moderate',
    };

    final simulationResult = <String, dynamic>{
      'total_invested': 60000.0,
      'estimated_return': 85000.0,
      'annual_rate': 7.0,
      'breakdown': [],
    };

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, SimulationResult] on success',
      build: () {
        when(mockSimulateReturns(any)).thenAnswer((_) async => simulationResult);
        return bloc;
      },
      act: (b) => b.add(SimulateReturns(simulationInput)),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<SimulationResult>().having(
          (s) => s.result['estimated_return'],
          'estimated_return',
          85000.0,
        ),
      ],
      verify: (_) => verify(mockSimulateReturns(simulationInput)).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on exception',
      build: () {
        when(mockSimulateReturns(any)).thenThrow(Exception('Simulation service down'));
        return bloc;
      },
      act: (b) => b.add(SimulateReturns(simulationInput)),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<InvestmentError>(),
      ],
    );
  });

  // ── LoadIndices ─────────────────────────────────────────────────────────────

  group('LoadIndices', () {
    final indices = [makeIndex(), makeIndex(ticker: 'DAX')];

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, IndicesLoaded] on success',
      build: () {
        when(mockGetIndices()).thenAnswer((_) async => indices);
        return bloc;
      },
      act: (b) => b.add(const LoadIndices()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<IndicesLoaded>().having(
          (s) => s.indices.length,
          'indices length',
          2,
        ),
      ],
      verify: (_) => verify(mockGetIndices()).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, IndicesLoaded] with empty list',
      build: () {
        when(mockGetIndices()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadIndices()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<IndicesLoaded>().having((s) => s.indices, 'indices', isEmpty),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on exception',
      build: () {
        when(mockGetIndices()).thenThrow(Exception('Market data unavailable'));
        return bloc;
      },
      act: (b) => b.add(const LoadIndices()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<InvestmentError>(),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits IndicesLoaded with correct ticker values',
      build: () {
        when(mockGetIndices()).thenAnswer((_) async => indices);
        return bloc;
      },
      act: (b) => b.add(const LoadIndices()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<IndicesLoaded>().having(
          (s) => s.indices.first.ticker,
          'first ticker',
          'SPX',
        ),
      ],
    );
  });

  // ── LoadGlossary ────────────────────────────────────────────────────────────

  group('LoadGlossary', () {
    final glossaryTerms = [
      {'term': 'ETF', 'definition': 'Exchange-Traded Fund'},
      {'term': 'Diversification', 'definition': 'Spreading risk across assets'},
    ];

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, GlossaryLoaded] on success',
      build: () {
        when(mockGetGlossary()).thenAnswer((_) async => glossaryTerms);
        return bloc;
      },
      act: (b) => b.add(const LoadGlossary()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<GlossaryLoaded>().having(
          (s) => s.terms.length,
          'terms length',
          2,
        ),
      ],
      verify: (_) => verify(mockGetGlossary()).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, GlossaryLoaded] with empty list',
      build: () {
        when(mockGetGlossary()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadGlossary()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<GlossaryLoaded>().having((s) => s.terms, 'terms', isEmpty),
      ],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits [InvestmentLoading, InvestmentError] on exception',
      build: () {
        when(mockGetGlossary()).thenThrow(Exception('Glossary unavailable'));
        return bloc;
      },
      act: (b) => b.add(const LoadGlossary()),
      expect: () => [
        isA<InvestmentLoading>(),
        isA<InvestmentError>(),
      ],
    );
  });

  // ── LoadChart ───────────────────────────────────────────────────────────────

  group('LoadChart', () {
    final chartData = <String, dynamic>{
      'points': [
        {'date': '2026-04-01', 'value': 5100.0},
        {'date': '2026-04-02', 'value': 5150.0},
        {'date': '2026-04-09', 'value': 5200.0},
      ],
    };

    blocTest<InvestmentBloc, InvestmentState>(
      'emits ChartLoaded with ticker and default period on success',
      build: () {
        when(mockRepository.getChart(any, any)).thenAnswer((_) async => chartData);
        return bloc;
      },
      act: (b) => b.add(const LoadChart('SPX')),
      expect: () => [
        isA<ChartLoaded>()
            .having((s) => s.ticker, 'ticker', 'SPX')
            .having((s) => s.period, 'period', '7d')
            .having((s) => s.points.length, 'points length', 3),
      ],
      verify: (_) => verify(mockRepository.getChart('SPX', '7d')).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits ChartLoaded with specified period',
      build: () {
        when(mockRepository.getChart(any, any)).thenAnswer((_) async => chartData);
        return bloc;
      },
      act: (b) => b.add(const LoadChart('DAX', period: '30d')),
      expect: () => [
        isA<ChartLoaded>()
            .having((s) => s.ticker, 'ticker', 'DAX')
            .having((s) => s.period, 'period', '30d'),
      ],
      verify: (_) => verify(mockRepository.getChart('DAX', '30d')).called(1),
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits InvestmentError on exception',
      build: () {
        when(mockRepository.getChart(any, any))
            .thenThrow(Exception('Chart data unavailable'));
        return bloc;
      },
      act: (b) => b.add(const LoadChart('SPX')),
      expect: () => [isA<InvestmentError>()],
    );

    blocTest<InvestmentBloc, InvestmentState>(
      'emits ChartLoaded with empty points list when no data',
      build: () {
        when(mockRepository.getChart(any, any)).thenAnswer(
          (_) async => {'points': <Map<String, dynamic>>[]},
        );
        return bloc;
      },
      act: (b) => b.add(const LoadChart('SPX')),
      expect: () => [
        isA<ChartLoaded>().having((s) => s.points, 'points', isEmpty),
      ],
    );
  });
}

