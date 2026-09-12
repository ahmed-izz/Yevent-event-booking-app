class Event {
  final String id;
  final String title;
  final String dateText;
  final String location;
  final String category;
  final String description;
  final int priceFromYER;
  final String imageUrl;
  final bool popular;
  final bool upcoming;

  const Event({
    required this.id,
    required this.title,
    required this.dateText,
    required this.location,
    required this.category,
    required this.description,
    required this.priceFromYER,
    required this.imageUrl,
    this.popular = false,
    this.upcoming = false,
  });
}