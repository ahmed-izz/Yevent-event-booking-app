import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:my_app/data/event_repository.dart';
import 'package:my_app/models/event.dart';
import 'package:my_app/widgets/event_card.dart';

enum _SortField { createdAt, eventDate, title }

class AllEventsScreen extends StatefulWidget {
  const AllEventsScreen({super.key});

  static const routeName = 'allEvents';
  static const routePath = '/events';

  @override
  State<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends State<AllEventsScreen> {
  final EventRepository _repo = EventRepository();

  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'All';

  _SortField _sortField = _SortField.createdAt;
  bool _sortAsc = false; // default: newest first

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

    final matchesCategory =
        _category == 'All' || category == _category.toLowerCase();

    return matchesQuery && matchesCategory;
  }

  int _cmpTitle(Event a, Event b) =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase());

  int _cmpEventDateUnknownLast(Event a, Event b) {
    if (!a.hasKnownDate && !b.hasKnownDate) return 0;
    if (!a.hasKnownDate) return 1;
    if (!b.hasKnownDate) return -1;
    return a.eventDate.compareTo(b.eventDate);
  }

  List<Event> _applySort(List<Event> list) {
    final out = [...list];

    if (_sortField == _SortField.title) {
      out.sort((a, b) {
        final r = _cmpTitle(a, b);
        return _sortAsc ? r : -r;
      });
      return out;
    }

    if (_sortField == _SortField.eventDate) {
      out.sort((a, b) {
        final r = _cmpEventDateUnknownLast(a, b);
        final rr = r == 0 ? _cmpTitle(a, b) : r;
        return _sortAsc ? rr : -rr;
      });
      return out;
    }

    // createdAt: repo stream is already createdAt DESC. For ASC we reverse.
    if (_sortAsc) return out.reversed.toList();
    return out;
  }

  String _sortLabel(_SortField f) {
    return switch (f) {
      _SortField.createdAt => 'Created time',
      _SortField.eventDate => 'Event date',
      _SortField.title => 'Title (A–Z)',
    };
  }

  String _sortSummary() {
    final dir = _sortAsc ? 'Ascending' : 'Descending';
    return '${_sortLabel(_sortField)} • $dir';
  }

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<(_SortField, bool)>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        var tempField = _sortField;
        var tempAsc = _sortAsc;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      child: Column(
                        children: [
                          RadioListTile<_SortField>(
                            value: _SortField.createdAt,
                            groupValue: tempField,
                            onChanged: (v) =>
                                setModalState(() => tempField = v!),
                            title: Text(_sortLabel(_SortField.createdAt)),
                          ),
                          const Divider(height: 0),
                          RadioListTile<_SortField>(
                            value: _SortField.eventDate,
                            groupValue: tempField,
                            onChanged: (v) =>
                                setModalState(() => tempField = v!),
                            title: Text(_sortLabel(_SortField.eventDate)),
                          ),
                          const Divider(height: 0),
                          RadioListTile<_SortField>(
                            value: _SortField.title,
                            groupValue: tempField,
                            onChanged: (v) =>
                                setModalState(() => tempField = v!),
                            title: Text(_sortLabel(_SortField.title)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Card(
                      child: SwitchListTile(
                        value: tempAsc,
                        onChanged: (v) => setModalState(() => tempAsc = v),
                        secondary: Icon(
                          tempAsc ? Icons.arrow_upward : Icons.arrow_downward,
                        ),
                        title: const Text('Ascending'),
                        subtitle: Text(tempAsc ? 'A → Z / Old → New' : 'Z → A / New → Old'),
                      ),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, (tempField, tempAsc)),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      _sortField = result.$1;
      _sortAsc = result.$2;
    });
  }

  void _openEvent(BuildContext context, Event e) {
    context.push('/event-details', extra: e);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: StreamBuilder<List<Event>>(
        stream: _repo.watchAll(),
        builder: (context, snap) {
          if (snap.hasError) {
            return SafeArea(
              child: Center(
                child: Text(
                  'Failed to load events: ${snap.error}',
                  style: tt.bodyMedium?.copyWith(color: cs.error),
                ),
              ),
            );
          }

          final loading =
              snap.connectionState == ConnectionState.waiting && !snap.hasData;
          final raw = snap.data ?? const <Event>[];

          final filtered = raw.where(_matches).toList();
          final events = _applySort(filtered);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: const Text('All Events'),
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) {
                                final c = cats[i];
                                final selected = c == _category;
                                return ChoiceChip(
                                  label: Text(c),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _category = c),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      // NEW: Sort control matches app style
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.sort),
                          title: const Text('Sort'),
                          subtitle: Text(_sortSummary()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _openSortSheet,
                        ),
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
                      text: 'No events match your search/filter.',
                      icon: Icons.event_busy_outlined,
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
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: i == events.length - 1 ? 0 : 14,
                          ),
                          child: EventCard(
                            event: e,
                            compact: true,
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
              style: tt.bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}