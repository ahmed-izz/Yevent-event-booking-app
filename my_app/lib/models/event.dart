import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Event {
  final String id;
  final String title;

  /// Single source of truth for date/time.
  final DateTime eventDate;

  final String location;
  final String category;
  final String description;
  final int priceFromYER;
  final String imageUrl;

  final bool popular;

  /// Manual ranking for popular events (1 = top).
  final int? popularRank;

  /// Sentinel value for legacy docs that don't have a valid `eventDate`.
  static final DateTime unknownEventDate =
      DateTime.fromMillisecondsSinceEpoch(0);

  const Event({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.location,
    required this.category,
    required this.description,
    required this.priceFromYER,
    required this.imageUrl,
    this.popular = false,
    this.popularRank,
  });

  bool get hasKnownDate => eventDate != unknownEventDate;

  /// "Sunday, 4 April 2026" or "Date TBA"
  String get dateLabel =>
      hasKnownDate ? DateFormat('EEEE, d MMMM y').format(eventDate) : 'Date TBA';

  /// Example: "8:00 PM" or ""
  String get timeLabel =>
      hasKnownDate ? DateFormat('h:mm a').format(eventDate) : '';

  bool get isUpcoming => hasKnownDate && eventDate.isAfter(DateTime.now());

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime parsedDate = unknownEventDate;
    final ts = data['eventDate'];
    if (ts is Timestamp) parsedDate = ts.toDate();

    return Event(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      eventDate: parsedDate,
      location: (data['location'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      priceFromYER: _toInt(data['priceFromYER']),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      popular: data['popular'] == true,
      popularRank: _toNullableInt(data['popularRank']),
    );
  }
}