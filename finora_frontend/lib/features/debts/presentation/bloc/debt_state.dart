import '../../domain/entities/debt_entity.dart';

abstract class DebtState {
  const DebtState();
}

class DebtInitial extends DebtState {
  const DebtInitial();
}

class DebtLoading extends DebtState {
  const DebtLoading();
}

class DebtsLoaded extends DebtState {
  final List<DebtEntity> debts;
  const DebtsLoaded(this.debts);
}

class DebtCreated extends DebtState {
  final DebtEntity debt;
  const DebtCreated(this.debt);
}

class DebtUpdated extends DebtState {
  final DebtEntity debt;
  const DebtUpdated(this.debt);
}

class DebtDeleted extends DebtState {
  final String id;
  const DebtDeleted(this.id);
}

class StrategiesLoaded extends DebtState {
  final Map<String, dynamic> data;
  const StrategiesLoaded(this.data);
}

class LoanCalculated extends DebtState {
  final Map<String, dynamic> result;
  const LoanCalculated(this.result);
}

class DebtError extends DebtState {
  final String message;
  const DebtError(this.message);
}
