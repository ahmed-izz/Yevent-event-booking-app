import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/mock_events.dart';
import '../../widgets/event_card.dart';
import '../../state/app_state.dart';
import '../event/event_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final favs = MockEvents.events.where((e) => state.isFavorite(e.id)).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Favorites', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (favs.isEmpty)
            const Text('No favorites yet.')
          else
            ...favs.map(
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