import '../entities/debt_entity.dart';

abstract class DebtsRepository {
  Future<List<DebtEntity>> getDebts();
  Future<DebtEntity> createDebt(Map<String, dynamic> data);
  Future<DebtEntity> updateDebt(String id, Map<String, dynamic> data);
  Future<void> deleteDebt(String id);
  Future<Map<String, dynamic>> getStrategies();
  Future<Map<String, dynamic>> calculateLoan(Map<String, dynamic> data);
  Future<Map<String, dynamic>> calculateMortgage(Map<String, dynamic> data);
}
