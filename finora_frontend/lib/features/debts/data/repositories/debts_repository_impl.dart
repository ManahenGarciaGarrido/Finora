import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debts_repository.dart';
import '../datasources/debts_remote_datasource.dart';

class DebtsRepositoryImpl implements DebtsRepository {
  final DebtsRemoteDataSource _ds;
  DebtsRepositoryImpl(this._ds);

  @override
  Future<List<DebtEntity>> getDebts() => _ds.getDebts();

  @override
  Future<DebtEntity> createDebt(Map<String, dynamic> data) =>
      _ds.createDebt(data);

  @override
  Future<DebtEntity> updateDebt(String id, Map<String, dynamic> data) =>
      _ds.updateDebt(id, data);

  @override
  Future<void> deleteDebt(String id) => _ds.deleteDebt(id);

  @override
  Future<Map<String, dynamic>> getStrategies() => _ds.getStrategies();

  @override
  Future<Map<String, dynamic>> calculateLoan(Map<String, dynamic> data) =>
      _ds.calculateLoan(data);

  @override
  Future<Map<String, dynamic>> calculateMortgage(Map<String, dynamic> data) =>
      _ds.calculateMortgage(data);
}
