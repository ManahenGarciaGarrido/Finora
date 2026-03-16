abstract class InvestmentEvent {
  const InvestmentEvent();
}

class LoadProfile extends InvestmentEvent {
  const LoadProfile();
}

class SaveProfile extends InvestmentEvent {
  final Map<String, dynamic> data;
  const SaveProfile(this.data);
}

class LoadPortfolioSuggestion extends InvestmentEvent {
  const LoadPortfolioSuggestion();
}

class SimulateReturns extends InvestmentEvent {
  final Map<String, dynamic> data;
  const SimulateReturns(this.data);
}

class LoadIndices extends InvestmentEvent {
  const LoadIndices();
}

class LoadGlossary extends InvestmentEvent {
  const LoadGlossary();
}
