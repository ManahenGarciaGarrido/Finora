import '../entities/investor_profile_entity.dart';
import '../repositories/investments_repository.dart';

class SaveProfileUseCase {
  final InvestmentsRepository _repo;
  SaveProfileUseCase(this._repo);
  Future<InvestorProfileEntity> call(Map<String, dynamic> data) =>
      _repo.saveProfile(data);
}
