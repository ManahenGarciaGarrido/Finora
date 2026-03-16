import '../../domain/entities/investor_profile_entity.dart';
import '../../domain/entities/portfolio_suggestion_entity.dart';
import '../../domain/entities/market_index_entity.dart';

abstract class InvestmentState {
  const InvestmentState();
}

class InvestmentInitial extends InvestmentState {
  const InvestmentInitial();
}

class InvestmentLoading extends InvestmentState {
  const InvestmentLoading();
}

class ProfileLoaded extends InvestmentState {
  final InvestorProfileEntity? profile;
  const ProfileLoaded(this.profile);
}

class ProfileSaved extends InvestmentState {
  final InvestorProfileEntity profile;
  const ProfileSaved(this.profile);
}

class PortfolioLoaded extends InvestmentState {
  final PortfolioSuggestionEntity suggestion;
  const PortfolioLoaded(this.suggestion);
}

class SimulationResult extends InvestmentState {
  final Map<String, dynamic> result;
  const SimulationResult(this.result);
}

class IndicesLoaded extends InvestmentState {
  final List<MarketIndexEntity> indices;
  const IndicesLoaded(this.indices);
}

class GlossaryLoaded extends InvestmentState {
  final List<Map<String, dynamic>> terms;
  const GlossaryLoaded(this.terms);
}

class InvestmentError extends InvestmentState {
  final String message;
  const InvestmentError(this.message);
}
