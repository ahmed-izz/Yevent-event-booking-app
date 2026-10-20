import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/event_repository.dart';
import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../widgets/event_card.dart';
import '../event/event_details_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = EventRepository();
    final state = context.watch<AppState>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      child: StreamBuilder<List<Event>>(
        stream: repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: _MessageCard(
                icon: Icons.error_outline,
                title: 'Couldn’t load favorites',
                body: 'Please check your connection and try again.',
                toneColor: cs.error,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!;
          final favs = all.where((e) => state.isFavorite(e.id)).toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Favorites',
                          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (favs.isNotEmpty)
                        Text(
                          '${favs.length}',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (favs.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: _MessageCard(
                      icon: Icons.favorite_border,
                      title: 'No favorites yet',
                      body: 'Tap the heart icon on any event to save it here.',
                      toneColor: cs.primary,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  sliver: SliverList.separated(
                    itemCount: favs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = favs[i];
                      return EventCard(
                        event: e,
                        compact: true,
                        onTap: () => context.push(EventDetailsScreen.routeForId(e.id), extra: e),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.toneColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: toneColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toneColor.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: toneColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
