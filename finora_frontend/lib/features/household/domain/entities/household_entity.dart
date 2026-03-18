class HouseholdEntity {
  final String id;
  final String name;
  final String ownerId;
  final String? inviteCode;
  final DateTime createdAt;

  const HouseholdEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    this.inviteCode,
    required this.createdAt,
  });
}
