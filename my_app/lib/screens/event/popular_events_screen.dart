import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:my_app/data/event_repository.dart';
import 'package:my_app/models/event.dart';
import 'package:my_app/state/app_state.dart';
import 'package:my_app/widgets/event_card.dart';

class PopularEventsScreen extends StatefulWidget {
  const PopularEventsScreen({super.key});

  static const routeName = 'popularEvents';
  static const routePath = '/popular-events';

  @override
  State<PopularEventsScreen> createState() => _PopularEventsScreenState();
}

class _PopularEventsScreenState extends State<PopularEventsScreen> {
  final EventRepository _repo = EventRepository();

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'All';

  late final Stream<List<String>> _categoriesStream;

  @override
  void initState() {
    super.initState();

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

    final matchesCategory = _category == 'All' || category == _category.toLowerCase();

    return matchesQuery && matchesCategory;
  }

  void _openEvent(BuildContext context, Event e) {
    context.push('/event-details', extra: e);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final appState = context.watch<AppState>();

    return Scaffold(
      body: StreamBuilder<List<Event>>(
        stream: _repo.watchPopular(),
        builder: (context, snap) {
          if (snap.hasError) {
            return SafeArea(
              child: Center(
                child: Text(
                  'Failed to load popular events: ${snap.error}',
                  style: tt.bodyMedium?.copyWith(color: cs.error),
                ),
              ),
            );
          }

          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;

          final raw = snap.data ?? const <Event>[];

          // filter + keep rank-order (defensive)
          final events = raw.where(_matches).toList()
            ..sort((a, b) {
              final ar = a.popularRank ?? (1 << 30);
              final br = b.popularRank ?? (1 << 30);
              return ar.compareTo(br);
            });

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Text('Popular Events'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search popular events...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () => _searchCtrl.clear(),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<List<String>>(
                        stream: _categoriesStream,
                        builder: (context, catSnap) {
                          final cats = catSnap.data ?? const <String>['All'];

                          if (!cats.contains(_category)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _category = 'All');
                            });
                          }

                          return SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: cats.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final c = cats[i];
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
              if (loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (events.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: _EmptyStateCard(
                      text: 'No popular events match your search/filter.',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final e = events[i];
                        final isFav = appState.isFavorite(e.id);

                        return Padding(
                          padding: EdgeInsets.only(bottom: i == events.length - 1 ? 0 : 14),
                          child: EventCard(
                            event: e,
                            compact: true,

                            // FIX: show the assigned Firestore rank
                            rank: e.popularRank,

                            trailing: IconButton(
                              tooltip: isFav ? 'Remove favorite' : 'Add favorite',
                              onPressed: () => appState.toggleFavorite(e),
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : cs.onSurfaceVariant,
                              ),
                            ),
                            onTap: () => _openEvent(context, e),
                          ),
                        );
                      },
                      childCount: events.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String text;
  final IconData icon;

  const _EmptyStateCard({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}