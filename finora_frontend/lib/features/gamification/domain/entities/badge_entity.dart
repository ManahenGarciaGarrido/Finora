class BadgeEntity {
  final String id;
  final String badgeKey;
  final String name;
  final String? description;
  final String? icon;
  final String? category;
  final bool isEarned;
  final String? earnedAt;

  const BadgeEntity({
    required this.id,
    required this.badgeKey,
    required this.name,
    this.description,
    this.icon,
    this.category,
    required this.isEarned,
    this.earnedAt,
  });
}
