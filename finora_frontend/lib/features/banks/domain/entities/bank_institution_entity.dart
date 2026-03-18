import 'package:equatable/equatable.dart';

/// Represents a bank/financial institution available for Open Banking connection (RF-10)
class BankInstitutionEntity extends Equatable {
  final String id;
  final String name;
  final String? logo;
  final String? bic;
  final List<String> countries;

  const BankInstitutionEntity({
    required this.id,
    required this.name,
    this.logo,
    this.bic,
    this.countries = const [],
  });

  @override
  List<Object?> get props => [id, name, logo, bic, countries];
}
