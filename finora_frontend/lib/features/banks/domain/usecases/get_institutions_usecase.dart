import '../entities/bank_institution_entity.dart';
import '../repositories/bank_repository.dart';

class GetInstitutionsUseCase {
  final BankRepository repository;
  GetInstitutionsUseCase(this.repository);

  Future<List<BankInstitutionEntity>> call({String country = 'ES'}) =>
      repository.getInstitutions(country: country);
}
