import '../models/event.dart';

class MockEvents {
  static final events = <Event>[
    Event(
      id: 'e1',
      title: 'Yemeni Architecture Night',
      eventDate: DateTime(2026, 1, 12, 18, 0),
      location: 'Sana’a - Yemen',
      category: 'Cultural / Architecture',
      description:
          'Join us for a curated evening highlighting modern interpretations of traditional Yemeni villas.',
      priceFromYER: 10000,
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200',
      popular: true,
    ),
    Event(
      id: 'e2',
      title: 'Aden Beach Music Jam',
      eventDate: DateTime(2026, 3, 20, 17, 0),
      location: 'Aden - Yemen',
      category: 'Music',
      description: 'A sunset beach jam with local artists and DJs.',
      priceFromYER: 6000,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200',
      popular: true,
    ),
    Event(
      id: 'e3',
      title: 'Taiz Art Workshop',
      eventDate: DateTime(2026, 4, 4, 10, 0),
      location: 'Taiz - Yemen',
      category: 'Workshop',
      description: 'Hands-on painting and sketching workshop for all levels.',
      priceFromYER: 5000,
      imageUrl:
          'https://images.unsplash.com/photo-1526481280695-3c687fd5432c?w=1200',
      popular: false,
    ),
  ];
}