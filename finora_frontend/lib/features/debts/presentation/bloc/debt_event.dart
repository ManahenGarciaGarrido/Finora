abstract class DebtEvent {
  const DebtEvent();
}

class LoadDebts extends DebtEvent {
  const LoadDebts();
}

class CreateDebt extends DebtEvent {
  final Map<String, dynamic> data;
  const CreateDebt(this.data);
}

class UpdateDebt extends DebtEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateDebt(this.id, this.data);
}

class DeleteDebt extends DebtEvent {
  final String id;
  const DeleteDebt(this.id);
}

class LoadStrategies extends DebtEvent {
  const LoadStrategies();
}

class CalculateLoan extends DebtEvent {
  final Map<String, dynamic> data;
  const CalculateLoan(this.data);
}

class CalculateMortgage extends DebtEvent {
  final Map<String, dynamic> data;
  const CalculateMortgage(this.data);
}
