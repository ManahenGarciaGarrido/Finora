import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import '../../domain/usecases/save_profile_usecase.dart';
import '../../domain/usecases/get_portfolio_suggestion_usecase.dart';
import '../../domain/usecases/simulate_returns_usecase.dart';
import '../../domain/usecases/get_indices_usecase.dart';
import '../../domain/usecases/get_glossary_usecase.dart';
import '../../domain/repositories/investments_repository.dart';
import 'investment_event.dart';
import 'investment_state.dart';

class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState> {
  final GetProfileUseCase getProfile;
  final SaveProfileUseCase saveProfile;
  final GetPortfolioSuggestionUseCase getPortfolioSuggestion;
  final SimulateReturnsUseCase simulateReturns;
  final GetIndicesUseCase getIndices;
  final GetGlossaryUseCase getGlossary;
  final InvestmentsRepository repository;

  InvestmentBloc({
    required this.getProfile,
    required this.saveProfile,
    required this.getPortfolioSuggestion,
    required this.simulateReturns,
    required this.getIndices,
    required this.getGlossary,
    required this.repository,
  }) : super(const InvestmentInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<SaveProfile>(_onSaveProfile);
    on<LoadPortfolioSuggestion>(_onLoadPortfolio);
    on<SimulateReturns>(_onSimulate);
    on<LoadIndices>(_onLoadIndices);
    on<LoadGlossary>(_onLoadGlossary);
    on<LoadChart>(_onLoadChart);
  }

  Future<void> _onLoadProfile(
    LoadProfile e,
    Emitter<InvestmentState> emit,
  ) async {
    emit(const InvestmentLoading());
    try {
      emit(ProfileLoaded(await getProfile()));
    } catch (err) {
      emit(InvestmentError(_msg(err)));
    }
  }

  Future<void> _onSaveProfile(
    SaveProfile e,
    Emitter<InvestmentState> emit,
  ) async {
    emit(const InvestmentLoading());
    try {
      emit(ProfileSaved(await saveProfile(e.data)));
    } catch (err) {
      emit(InvestmentError(_msg(err)));
    }
  }

  Future<void> _onLoadPortfolio(
    LoadPortfolioSuggestion e,
    Emitter<InvestmentState> emit,
  ) async {
    emit(const InvestmentLoading());
    try {
      emit(PortfolioLoaded(await getPortfolioSuggestion()));
    } catch (_) {}
  }

  Future<void> _onSimulate(
    SimulateReturns e,
    Emitter<InvestmentState> emit,
  ) async {
    emit(const InvestmentLoading());
    try {
      emit(SimulationResult(await simulateReturns(e.data)));
    } catch (err) {
      emit(InvestmentError(_msg(err)));
    }
  }

  Future<void> _onLoadIndices(
    LoadIndices e,
    Emitter<InvestmentState> emit,
  ) async {
    emit(const InvestmentLoading());
    try {
      emit(IndicesLoaded(await getIndices()));
    } catch (err) {
      emit(InvestmentError(_msg(err)));
    }
  }

  Future<void> _onLoadGlossary(
    LoadGlossary e,
    Emitter<InvestmentState> emit,
  ) async {
    emit(const InvestmentLoading());
    try {
      emit(GlossaryLoaded(await getGlossary()));
    } catch (err) {
      emit(InvestmentError(_msg(err)));
    }
  }

  Future<void> _onLoadChart(LoadChart e, Emitter<InvestmentState> emit) async {
    try {
      final data = await repository.getChart(e.ticker, e.period);
      final points = List<Map<String, dynamic>>.from(data['points'] as List);
      emit(ChartLoaded(ticker: e.ticker, period: e.period, points: points));
    } catch (err) {
      emit(InvestmentError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
