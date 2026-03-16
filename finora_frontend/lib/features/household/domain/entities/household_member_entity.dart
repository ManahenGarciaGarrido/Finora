class HouseholdMemberEntity {
  final String id;
  final String userId;
  final String role;
  final String? name;
  final String? email;
  final DateTime joinedAt;

  const HouseholdMemberEntity({
    required this.id,
    required this.userId,
    required this.role,
    this.name,
    this.email,
    required this.joinedAt,
  });

  bool get isOwner => role == 'owner';
}
