import '../entities/bank_sync_status_entity.dart';
import '../repositories/bank_repository.dart';

class GetSyncStatusUseCase {
  final BankRepository repository;
  GetSyncStatusUseCase(this.repository);

  Future<BankSyncStatusEntity> call(String connectionId) =>
      repository.getSyncStatus(connectionId);
}
