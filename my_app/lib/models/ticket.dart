class Ticket {
  final String id;
  final String eventId;
  final String eventTitle;
  final String tier;
  final int quantity;
  final int totalYER;
  final String dateText;

  const Ticket({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.tier,
    required this.quantity,
    required this.totalYER,
    required this.dateText,
  });
}