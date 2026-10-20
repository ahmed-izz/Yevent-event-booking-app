import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import 'package:my_app/data/event_repository.dart';
import 'package:my_app/models/event.dart';
import 'package:my_app/screens/event/all_events_screen.dart';
import 'package:my_app/screens/event/popular_events_screen.dart';
import 'package:my_app/state/app_state.dart';
import 'package:my_app/widgets/app_wordmark.dart';
import 'package:my_app/widgets/event_card.dart';
import '../event/event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventRepository _repo = EventRepository();

  late final Stream<List<Event>> _upcomingStream;
  late final Stream<List<Event>> _popularStream;

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'All';

  late final Stream<List<String>> _categoriesStream;

  static const double _hPad = 16;
  static const double _gapXs = 6;
  static const double _gapSm = 10;
  static const double _gapMd = 14;
  static const double _gapLg = 20;

  @override
  void initState() {
    super.initState();
    _upcomingStream = _repo.watchUpcoming();
    _popularStream = _repo.watchPopular();

    _categoriesStream = FirebaseFirestore.instance
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final items = snap.docs.map((d) {
        final data = d.data();
        final name = (data['name'] ?? '').toString().trim();
        final orderRaw = data['order'];
        final order = (orderRaw is num) ? orderRaw.toInt() : 9999;
        return (name: name, order: order);
      }).where((x) => x.name.isNotEmpty).toList()
        ..sort((a, b) {
          final o = a.order.compareTo(b.order);
          if (o != 0) return o;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

      return <String>['All', ...items.map((e) => e.name)];
    });

    _searchCtrl.addListener(() {
      final v = _searchCtrl.text.trim().toLowerCase();
      if (v != _query) setState(() => _query = v);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(Event e) {
    final q = _query;

    final title = e.title.toLowerCase();
    final location = e.location.toLowerCase();
    final category = e.category.toLowerCase();

    final matchesQuery =
        q.isEmpty || title.contains(q) || location.contains(q) || category.contains(q);

    final matchesCategory =
        _category == 'All' || category == _category.toLowerCase();

    return matchesQuery && matchesCategory;
  }

  void _openEvent(Event e) {
    context.push(EventDetailsScreen.routeForId(e.id), extra: e);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final appState = context.watch<AppState>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: true,
            title: const AppWordmark(height: 28),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_hPad, _gapMd, _hPad, _gapSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search events, locations, categories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => _searchCtrl.clear(),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: _gapSm),

                  StreamBuilder<List<String>>(
                    stream: _categoriesStream,
                    builder: (context, snap) {
                      final categories = snap.data ?? const <String>['All'];

                      if (!categories.contains(_category)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _category = 'All');
                        });
                      }

                      return SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final c = categories[i];
                            final selected = c == _category;
                            return ChoiceChip(
                              label: Text(c),
                              selected: selected,
                              onSelected: (_) => setState(() => _category = c),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_hPad, _gapSm, _hPad, _gapLg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // UPCOMING header + see all events
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Upcoming Events',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(AllEventsScreen.routePath),
                      child: const Text('See All Events →'),
                    ),
                  ],
                ),
                const SizedBox(height: _gapSm),

                StreamBuilder<List<Event>>(
                  stream: _upcomingStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _InlineMessage(
                        text: 'Upcoming failed: ${snapshot.error}',
                        color: cs.error,
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const _HorizontalCardShimmer(
                        itemHeight: 266,
                        itemWidth: 304,
                      );
                    }

                    final raw = snapshot.data ?? const <Event>[];
                    final events = raw.where(_matches).toList();

                    if (events.isEmpty) {
                      return const _EmptyStateCard(
                        text: 'No upcoming events match your search/filter.',
                      );
                    }

                    return SizedBox(
                      height: 266,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final e = events[i];
                          return SizedBox(
                            width: 304,
                            child: EventCard(
                              event: e,
                              onTap: () => _openEvent(e),
                              compact: false,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: _gapLg),

                // POPULAR header + see all popular
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Popular',
                        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(PopularEventsScreen.routePath),
                      child: const Text('See All Popular Events →'),
                    ),
                  ],
                ),
                const SizedBox(height: _gapXs),

                StreamBuilder<List<Event>>(
                  stream: _popularStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _InlineMessage(
                        text:
                            'Popular failed: ${snapshot.error}\n\nIf it says "requires an index", create it in Firebase Console.',
                        color: cs.error,
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const _VerticalTileShimmer(count: 3, gap: 10);
                    }

                    final raw = snapshot.data ?? const <Event>[];
                    final filtered = raw.where(_matches).toList();

                    if (filtered.isEmpty) {
                      return const _EmptyStateCard(
                        text: 'No popular events match your search/filter.',
                      );
                    }

                    final top = filtered.take(3).toList();

                    return Column(
                      children: [
                        for (int i = 0; i < top.length; i++) ...[
                          Builder(builder: (context) {
                            final e = top[i];
                            final isFav = appState.isFavorite(e.id);

                            return EventCard(
                              event: e,
                              onTap: () => _openEvent(e),
                              compact: true,
                              rank: i + 1,
                              trailing: IconButton(
                                tooltip: isFav ? 'Remove favorite' : 'Add favorite',
                                onPressed: () => appState.toggleFavorite(e),
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          }),
                          if (i != top.length - 1) const SizedBox(height: 14),
                        ],
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String text;
  final Color color;

  const _InlineMessage({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: tt.bodyMedium?.copyWith(color: color)),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String text;

  const _EmptyStateCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _HorizontalCardShimmer extends StatelessWidget {
  final double itemHeight;
  final double itemWidth;

  const _HorizontalCardShimmer({
    required this.itemHeight,
    required this.itemWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: cs.surfaceVariant.withOpacity(0.7),
            highlightColor: cs.surface.withOpacity(0.9),
            child: Container(
              width: itemWidth,
              height: itemHeight,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerticalTileShimmer extends StatelessWidget {
  final int count;
  final double gap;

  const _VerticalTileShimmer({required this.count, this.gap = 10});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(count, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i == count - 1 ? 0 : gap),
          child: Shimmer.fromColors(
            baseColor: cs.surfaceVariant.withOpacity(0.7),
            highlightColor: cs.surface.withOpacity(0.9),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: cs.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      }),
    );
  }
}