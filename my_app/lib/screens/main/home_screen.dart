import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock_events.dart';
import '../../models/event.dart';
import '../../widgets/event_card.dart';
import '../event/event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';
  int catIndex = 0;

  final categories = const ['All', 'Sports', 'Concerts', 'Galleries'];

  List<Event> get filtered {
    final q = query.trim().toLowerCase();
    var list = MockEvents.events;

    if (q.isNotEmpty) {
      list = list.where((e) => e.title.toLowerCase().contains(q)).toList();
    }
    // categories here are just UI (mock)
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = filtered.where((e) => e.upcoming).toList();
    final popular = filtered.where((e) => e.popular).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Yevent', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              hintText: 'Search events',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final selected = i == catIndex;
                return ChoiceChip(
                  label: Text(categories[i]),
                  selected: selected,
                  onSelected: (_) => setState(() => catIndex = i),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
          const SizedBox(height: 18),

          const Text('Upcoming Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: upcoming.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final e = upcoming[i];
                return SizedBox(
                  width: 280,
                  child: EventCard(
                    event: e,
                    onTap: () => context.push(EventDetailsScreen.routePath, extra: e),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),
          const Text('Popular Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...popular.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EventCard(
                event: e,
                compact: true,
                onTap: () => context.push(EventDetailsScreen.routePath, extra: e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}