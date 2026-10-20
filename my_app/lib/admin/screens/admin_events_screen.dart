import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../widgets/event_editor_dialog.dart';

enum _SortField { createdAt, eventDate, title, priceFrom }
enum _DateFilter { all, future, past, tba }

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final TextEditingController _search = TextEditingController();

  bool popularOnly = false;
  _DateFilter dateFilter = _DateFilter.all;

  _SortField sortField = _SortField.createdAt;
  bool sortAsc = false; // newest first

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = dt.toLocal();
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  bool _matchesSearch(Event e, String q) {
    if (q.isEmpty) return true;
    final text = ('${e.title} ${e.location} ${e.category}').toLowerCase();
    return text.contains(q);
  }

  bool _matchesDateFilter(Event e) {
    final now = DateTime.now();
    return switch (dateFilter) {
      _DateFilter.all => true,
      _DateFilter.tba => !e.hasKnownDate,
      _DateFilter.future => e.hasKnownDate && e.eventDate.isAfter(now),
      _DateFilter.past => e.hasKnownDate && !e.eventDate.isAfter(now),
    };
  }

  int _cmpTitle(Event a, Event b) =>
      a.title.toLowerCase().compareTo(b.title.toLowerCase());

  int _cmpEventDateUnknownLast(Event a, Event b) {
    if (!a.hasKnownDate && !b.hasKnownDate) return 0;
    if (!a.hasKnownDate) return 1;
    if (!b.hasKnownDate) return -1;
    return a.eventDate.compareTo(b.eventDate);
  }

  List<Event> _applyUiFilters(List<Event> list) {
    final q = _search.text.trim().toLowerCase();

    var out = list
        .where((e) => _matchesSearch(e, q))
        .where(_matchesDateFilter)
        .toList();

    if (popularOnly) out = out.where((e) => e.popular).toList();

    int cmp(Event a, Event b) {
      return switch (sortField) {
        _SortField.createdAt => 0, // keep Firestore order
        _SortField.eventDate => _cmpEventDateUnknownLast(a, b),
        _SortField.title => _cmpTitle(a, b),
        _SortField.priceFrom => a.priceFromYER.compareTo(b.priceFromYER),
      };
    }

    if (sortField == _SortField.createdAt) {
      if (sortAsc) out = out.reversed.toList();
      return out;
    }

    out.sort((a, b) {
      final r = cmp(a, b);
      final rr = r == 0 ? _cmpTitle(a, b) : r;
      return sortAsc ? rr : -rr;
    });

    return out;
  }

  int? get _sortColumnIndex => switch (sortField) {
        _SortField.title => 0,
        _SortField.eventDate => 1,
        _SortField.priceFrom => 4,
        _SortField.createdAt => null,
      };

  void _setSort(_SortField f) {
    setState(() {
      if (sortField == f) {
        sortAsc = !sortAsc;
      } else {
        sortField = f;
        // better UX: first click sorts ascending
        sortAsc = true;
      }
    });
  }

  String _dateLabel(Event e) => e.hasKnownDate ? _fmtDate(e.eventDate) : 'TBA';

  ({String label, Color bg, Color fg}) _statusSpec(BuildContext context, Event e) {
    final cs = Theme.of(context).colorScheme;
    if (!e.hasKnownDate) {
      return (label: 'TBA', bg: cs.surfaceContainerHighest, fg: cs.onSurface);
    }
    final now = DateTime.now();
    final future = e.eventDate.isAfter(now);
    if (future) {
      return (label: 'Future', bg: cs.primaryContainer, fg: cs.onPrimaryContainer);
    }
    return (label: 'Past', bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant);
  }

  Future<void> _togglePopular(String eventId, bool newValue) async {
    await FirebaseFirestore.instance.collection('events').doc(eventId).update({
      'popular': newValue,
    });
  }

  Future<void> _deleteEvent(Event e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Delete "${e.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance.collection('events').doc(e.id).delete();
    }
  }

  Widget _thumb(Event e) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: (e.imageUrl.trim().isEmpty)
          ? Container(
              width: 40,
              height: 40,
              color: Colors.black12,
              child: const Icon(Icons.image_not_supported_outlined, size: 18),
            )
          : Image.network(
              e.imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 40,
                height: 40,
                color: Colors.black12,
                child: const Icon(Icons.broken_image_outlined, size: 18),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsRef = FirebaseFirestore.instance.collection('events');
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text('Events', style: Theme.of(context).textTheme.titleLarge),
              ),
              FilledButton.icon(
                onPressed: () => showDialog(context: context, builder: (_) => const EventEditorDialog()),
                icon: const Icon(Icons.add),
                label: const Text('Add event'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search + Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Search (title, location, category)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          label: const Text('Popular only'),
                          selected: popularOnly,
                          onSelected: (v) => setState(() => popularOnly = v),
                        ),
                        DropdownButton<_DateFilter>(
                          value: dateFilter,
                          items: const [
                            DropdownMenuItem(value: _DateFilter.all, child: Text('All dates')),
                            DropdownMenuItem(value: _DateFilter.future, child: Text('Future')),
                            DropdownMenuItem(value: _DateFilter.past, child: Text('Past')),
                            DropdownMenuItem(value: _DateFilter.tba, child: Text('TBA')),
                          ],
                          onChanged: (v) => v == null ? null : setState(() => dateFilter = v),
                        ),
                        if (isNarrow)
                          OutlinedButton.icon(
                            onPressed: () => setState(() => sortAsc = !sortAsc),
                            icon: Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
                            label: Text(sortAsc ? 'Asc' : 'Desc'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: eventsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

                final docs = snap.data?.docs ?? const [];
                final events = docs.map((d) => Event.fromFirestore(d)).toList();
                final filtered = _applyUiFilters(events);

                if (events.isEmpty) return const Center(child: Text('No events yet.'));
                if (filtered.isEmpty) return const Center(child: Text('No matching events.'));

                // Phone: keep a clean card list (your old style)
                if (isNarrow) {
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      final st = _statusSpec(context, e);

                      return Card(
                        child: ListTile(
                          leading: _thumb(e),
                          title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${e.location} • ${e.category}'),
                              const SizedBox(height: 2),
                              Text('Date: ${_dateLabel(e)}'),
                              Text('From: ${e.priceFromYER.toInt()} YER'),
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(st.label),
                                backgroundColor: st.bg,
                                labelStyle: TextStyle(color: st.fg, fontWeight: FontWeight.w600),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () => showDialog(context: context, builder: (_) => EventEditorDialog(event: e)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'popular') await _togglePopular(e.id, !e.popular);
                              if (v == 'edit' && context.mounted) {
                                showDialog(context: context, builder: (_) => EventEditorDialog(event: e));
                              }
                              if (v == 'delete') await _deleteEvent(e);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'popular',
                                child: Text(e.popular ? 'Unmark popular' : 'Mark popular'),
                              ),
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }

                // Desktop: FIXED table (full width + no icon wrapping)
                return LayoutBuilder(
                  builder: (context, c) {
                    return Card(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          // KEY FIX: force the table to be at least as wide as the page
                          constraints: BoxConstraints(minWidth: c.maxWidth),
                          child: DataTable(
                            horizontalMargin: 12,
                            columnSpacing: 18,
                            headingRowHeight: 44,
                            dataRowMinHeight: 56,
                            dataRowMaxHeight: 72,
                            sortColumnIndex: _sortColumnIndex,
                            sortAscending: sortAsc,
                            columns: [
                              DataColumn(
                                label: const Text('Event'),
                                onSort: (_, __) => _setSort(_SortField.title),
                              ),
                              DataColumn(
                                label: const Text('Date'),
                                onSort: (_, __) => _setSort(_SortField.eventDate),
                              ),
                              const DataColumn(label: Text('Category')),
                              const DataColumn(label: Text('Status')),
                              DataColumn(
                                numeric: true,
                                label: const Text('From (YER)'),
                                onSort: (_, __) => _setSort(_SortField.priceFrom),
                              ),
                              const DataColumn(label: Text('Popular')),
                              const DataColumn(label: Text('Actions')),
                            ],
                            rows: [
                              for (final e in filtered)
                                DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 420,
                                        child: Row(
                                          children: [
                                            _thumb(e),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    e.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                                  ),
                                                  Text(
                                                    '${e.location} • ${e.category}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () => showDialog(
                                        context: context,
                                        builder: (_) => EventEditorDialog(event: e),
                                      ),
                                    ),
                                    DataCell(Text(_dateLabel(e))),
                                    DataCell(Text(e.category)),
                                    DataCell(
                                      _StatusChip(spec: _statusSpec(context, e)),
                                    ),
                                    DataCell(Text(e.priceFromYER.toInt().toString())),
                                    DataCell(
                                      IconButton(
                                        tooltip: e.popular ? 'Unmark popular' : 'Mark popular',
                                        onPressed: () => _togglePopular(e.id, !e.popular),
                                        icon: Icon(
                                          e.popular ? Icons.favorite : Icons.favorite_border,
                                          color: e.popular ? Colors.red : null,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 110,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              tooltip: 'Edit',
                                              onPressed: () => showDialog(
                                                context: context,
                                                builder: (_) => EventEditorDialog(event: e),
                                              ),
                                              icon: const Icon(Icons.edit_outlined),
                                            ),
                                            IconButton(
                                              tooltip: 'Delete',
                                              onPressed: () => _deleteEvent(e),
                                              icon: const Icon(Icons.delete_outline),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.spec});
  final ({String label, Color bg, Color fg}) spec;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(spec.label),
      backgroundColor: spec.bg,
      labelStyle: TextStyle(color: spec.fg, fontWeight: FontWeight.w700),
      visualDensity: VisualDensity.compact,
    );
  }
}