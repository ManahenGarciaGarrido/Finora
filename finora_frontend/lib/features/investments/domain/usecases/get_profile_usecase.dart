import '../entities/investor_profile_entity.dart';
import '../repositories/investments_repository.dart';

class GetProfileUseCase {
  final InvestmentsRepository _repo;
  GetProfileUseCase(this._repo);
  Future<InvestorProfileEntity?> call() => _repo.getProfile();
}
