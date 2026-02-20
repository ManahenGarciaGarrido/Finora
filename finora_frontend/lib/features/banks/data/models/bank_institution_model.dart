import '../../domain/entities/bank_institution_entity.dart';

class BankInstitutionModel extends BankInstitutionEntity {
  const BankInstitutionModel({
    required super.id,
    required super.name,
    super.logo,
    super.bic,
    super.countries,
  });

  factory BankInstitutionModel.fromJson(Map<String, dynamic> json) {
    return BankInstitutionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      bic: json['bic'] as String?,
      countries: (json['countries'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
