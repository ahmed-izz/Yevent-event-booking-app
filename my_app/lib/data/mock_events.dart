import '../models/event.dart';

class MockEvents {
  static const events = <Event>[
    Event(
      id: 'e1',
      title: 'Yemeni Architecture Night',
      dateText: 'Monday, 12 Jan 2026',
      location: 'Sana’a - Yemen',
      category: 'Cultural / Architecture',
      description:
          'Join us for a curated evening highlighting modern interpretations of traditional Yemeni villas.',
      priceFromYER: 10000,
      imageUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200',
      upcoming: true,
      popular: true,
    ),
    Event(
      id: 'e2',
      title: 'Aden Beach Music Jam',
      dateText: 'Saturday, 20 Mar 2026',
      location: 'Aden - Yemen',
      category: 'Music',
      description: 'A sunset beach jam with local artists and DJs.',
      priceFromYER: 6000,
      imageUrl: 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200',
      upcoming: true,
      popular: true,
    ),
    Event(
      id: 'e3',
      title: 'Taiz Art Workshop',
      dateText: 'Sunday, 4 Apr 2026',
      location: 'Taiz - Yemen',
      category: 'Workshop',
      description: 'Hands-on painting and sketching workshop for all levels.',
      priceFromYER: 5000,
      imageUrl: 'https://images.unsplash.com/photo-1526481280695-3c687fd5432c?w=1200',
      upcoming: true,
    ),
    Event(
      id: 'e4',
      title: 'Sana’a International Coffee Exhibition',
      dateText: 'Friday, 12 Feb 2026',
      location: 'Sana’a - Yemen',
      category: 'Exhibition',
      description: 'Discover Yemeni coffee culture with tastings and talks.',
      priceFromYER: 7000,
      imageUrl: 'https://images.unsplash.com/photo-1512568400610-62da28bc8a13?w=1200',
      popular: true,
    ),
  ];
}