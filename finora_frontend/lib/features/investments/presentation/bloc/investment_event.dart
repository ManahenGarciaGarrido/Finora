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

class LoadChart extends InvestmentEvent {
  final String ticker;
  final String period; // '7d', '30d', '90d', '180d', '365d'
  const LoadChart(this.ticker, {this.period = '7d'});
}
