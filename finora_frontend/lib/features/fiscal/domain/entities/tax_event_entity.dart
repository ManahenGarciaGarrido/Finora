class TaxEventEntity {
  final String date;
  final String title;
  final String type;

  const TaxEventEntity({
    required this.date,
    required this.title,
    required this.type,
  });

  bool get isPast => DateTime.tryParse(date)?.isBefore(DateTime.now()) ?? false;
}
