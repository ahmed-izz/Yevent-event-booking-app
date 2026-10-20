import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventRepository {
  final FirebaseFirestore _db;
  EventRepository({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _events => _db.collection('events');

  Stream<List<Event>> watchAll() {
    return _events
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Event.fromFirestore(d)).toList());
  }

  Stream<List<Event>> watchUpcoming() {
    final now = Timestamp.fromDate(DateTime.now());

    return _events
        .where('eventDate', isGreaterThanOrEqualTo: now)
        .orderBy('eventDate')
        .snapshots()
        .map((s) => s.docs.map((d) => Event.fromFirestore(d)).toList());
  }

  Stream<List<Event>> watchPopular() {
    return _events
        .where('popular', isEqualTo: true)
        .where('popularRank', isGreaterThanOrEqualTo: 1)
        .orderBy('popularRank') // rank 1 first
        .snapshots()
        .map((s) => s.docs.map((d) => Event.fromFirestore(d)).toList());
  }
}