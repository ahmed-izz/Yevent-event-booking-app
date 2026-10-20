import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/event.dart';

class EventEditorDialog extends StatefulWidget {
  const EventEditorDialog({super.key, this.event});
  final Event? event;

  @override
  State<EventEditorDialog> createState() => _EventEditorDialogState();
}

class _TierInput {
  _TierInput({String name = '', String price = '0'})
    : nameCtrl = TextEditingController(text: name),
      priceCtrl = TextEditingController(text: price);

  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _EventEditorDialogState extends State<EventEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController title;
  late final TextEditingController location;
  late final TextEditingController description;
  late final TextEditingController imageUrl;
  late final TextEditingController popularRankCtrl;

  final List<_TierInput> _tiers = [];
  bool tiersLoading = false;

  bool popular = false;
  DateTime? eventDateTime;
  bool saving = false;

  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    title = TextEditingController(text: e?.title ?? '');
    location = TextEditingController(text: e?.location ?? '');
    description = TextEditingController(text: e?.description ?? '');
    imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    popularRankCtrl = TextEditingController(text: '');

    popular = e?.popular ?? false;

    // Treat "unknown" legacy date as not set (forces admin to pick a real date/time)
    final dt = e?.eventDate;
    eventDateTime = (dt == null || dt == Event.unknownEventDate) ? null : dt;

    _selectedCategory = (e?.category.trim().isNotEmpty ?? false)
        ? e!.category.trim()
        : null;

    if (e == null) {
      _tiers.add(_TierInput(name: 'General', price: '0'));
      // if user turns on Popular later, we’ll auto-fill rank = 1
    } else {
      _loadEventExtras(e.id);
    }
  }

  /// Loads tiers + popularRank (and any other fields we want to read directly from Firestore).
  Future<void> _loadEventExtras(String eventId) async {
    setState(() => tiersLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      final data = doc.data();
      final rawTiers = data?['tiers'];

      // ---- popularRank ----
      final pr = data?['popularRank'];
      if (pr is num) {
        popularRankCtrl.text = pr.toInt().toString();
      } else {
        // Keep empty if missing (rules require it only when Popular is ON)
        popularRankCtrl.text = '';
      }

      // ---- tiers ----
      final rows = <_TierInput>[];
      if (rawTiers is List) {
        for (final item in rawTiers) {
          if (item is Map) {
            rows.add(
              _TierInput(
                name: (item['name'] ?? '').toString(),
                price: (item['priceYER'] ?? 0).toString(),
              ),
            );
          }
        }
      }

      if (rows.isEmpty) {
        rows.add(
          _TierInput(
            name: 'General',
            price: (data?['priceFromYER'] ?? widget.event?.priceFromYER ?? 0)
                .toString(),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _tiers
          ..forEach((t) => t.dispose())
          ..clear();
        _tiers.addAll(rows);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tiers
          ..forEach((t) => t.dispose())
          ..clear();
        _tiers.add(
          _TierInput(
            name: 'General',
            price: (widget.event?.priceFromYER ?? 0).toString(),
          ),
        );
      });
    } finally {
      if (mounted) setState(() => tiersLoading = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    location.dispose();
    description.dispose();
    imageUrl.dispose();
    popularRankCtrl.dispose();
    for (final t in _tiers) {
      t.dispose();
    }
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = dt.toLocal();
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _pickEventDateTime() async {
    final now = DateTime.now();
    final initial = eventDateTime ?? now;

    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 10);

    final safeInitial = initial.isBefore(firstDate)
        ? firstDate
        : (initial.isAfter(lastDate) ? lastDate : initial);

    final date = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    setState(() {
      eventDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  String? _validateTitle(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    if (s.length < 3) return 'Min 3 characters';
    if (s.length > 120) return 'Max 120 characters';
    return null;
  }

  String? _validateNonEmpty(String? v) =>
      (v ?? '').trim().isEmpty ? 'Required' : null;

  String? _validateDescription(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    if (s.length < 10) return 'Min 10 characters';
    if (s.length > 2000) return 'Max 2000 characters';
    return null;
  }

  String? _validateUrl(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    final ok = s.startsWith('http://') || s.startsWith('https://');
    if (!ok) return 'Must start with http:// or https://';
    return null;
  }

  String? _validatePopularRank(String? v) {
    if (!popular) return null; // only required when Popular is ON
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Required';
    final n = int.tryParse(s);
    if (n == null) return 'Must be a number';
    if (n < 1 || n > 9999) return 'Must be between 1 and 9999';
    return null;
  }

  Future<void> _save({
    required bool hasAnyCategories,
    required List<String> activeCategoryNames,
  }) async {
    if (!hasAnyCategories) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add categories first')),
      );
      return;
    }
    if (activeCategoryNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please activate a category first')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final cat = _selectedCategory?.trim();
    if (cat == null || cat.isEmpty || !activeCategoryNames.contains(cat)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an active category')),
      );
      return;
    }

    if (eventDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose the event date & time')),
      );
      return;
    }

    // ---- Validate tiers ----
    if (_tiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ticket tier')),
      );
      return;
    }
    if (_tiers.length > 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Max 10 tiers')));
      return;
    }

    final tiers = <Map<String, dynamic>>[];
    final usedNames = <String>{};
    var minPrice = -1;

    for (final t in _tiers) {
      final name = t.nameCtrl.text.trim();
      final price = int.tryParse(t.priceCtrl.text.trim());

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Every tier needs a name')),
        );
        return;
      }
      if (name.length > 40) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tier name is too long (max 40)')),
        );
        return;
      }
      final nameKey = name.toLowerCase();
      if (usedNames.contains(nameKey)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Duplicate tier name: "$name"')));
        return;
      }
      usedNames.add(nameKey);

      if (price == null || price < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tier "$name" needs a valid price (0 or more)'),
          ),
        );
        return;
      }

      tiers.add({'name': name, 'priceYER': price});
      if (minPrice == -1 || price < minPrice) minPrice = price;
    }

    // ---- Validate Popular rank (required only when Popular is ON) ----
    int? popularRank;
    if (popular) {
      final parsed = int.tryParse(popularRankCtrl.text.trim());
      if (parsed == null || parsed < 1 || parsed > 9999) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Popular rank must be a number from 1 to 9999'),
          ),
        );
        return;
      }
      popularRank = parsed;
    }

    setState(() => saving = true);

    final eventsRef = FirebaseFirestore.instance.collection('events');

    // IMPORTANT:
    // - We do NOT write legacy fields (upcoming/dateText).
    // - On update we use merge:false to remove any legacy fields that exist.
    // - If Popular is OFF, we omit popularRank so it gets removed (merge:false).
    final baseData = <String, dynamic>{
      'title': title.text.trim(),
      'eventDate': Timestamp.fromDate(eventDateTime!),
      'location': location.text.trim(),
      'category': cat,
      'description': description.text.trim(),
      'priceFromYER': minPrice,
      'tiers': tiers,
      'imageUrl': imageUrl.text.trim(),
      'popular': popular,
      if (popularRank != null) 'popularRank': popularRank,
      'updatedAt': Timestamp.now(),
    };

    try {
      if (widget.event == null) {
        // CREATE
        await eventsRef.add({...baseData, 'createdAt': Timestamp.now()});
      } else {
        // UPDATE (overwrite doc)
        final ref = eventsRef.doc(widget.event!.id);
        final existing = await ref.get();
        final createdAt = existing.data()?['createdAt'];

        if (createdAt is! Timestamp) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This event is missing createdAt. Fix it in Firestore, then edit again.',
              ),
            ),
          );
          return;
        }

        await ref.set(
          {
            ...baseData,
            'createdAt':
                createdAt, // rules require createdAt unchanged on update
          },
          SetOptions(
            merge: false,
          ), // drops old fields (upcoming/dateText) + removes popularRank when Popular OFF
        );
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Save failed')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _buildTierRow(int index) {
    final t = _tiers[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: t.nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tier name',
                hintText: 'e.g. Regular, VIP',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: t.priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Price (YER)',
                hintText: '0',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Remove tier',
            onPressed: saving || _tiers.length <= 1
                ? null
                : () {
                    setState(() {
                      final removed = _tiers.removeAt(index);
                      removed.dispose();
                    });
                  },
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.event != null;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final categoriesStream = FirebaseFirestore.instance
        .collection('categories')
        .orderBy('order')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: categoriesStream,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];

        final allCategories = docs
            .map((d) {
              final data = d.data();
              final name = (data['name'] ?? '').toString().trim();
              final orderRaw = data['order'];
              final order = (orderRaw is num) ? orderRaw.toInt() : 9999;
              final isActiveRaw = data['isActive'];
              final isActive = (isActiveRaw is bool) ? isActiveRaw : false;
              return (name: name, order: order, isActive: isActive);
            })
            .where((c) => c.name.isNotEmpty)
            .toList();

        final hasAnyCategories = allCategories.isNotEmpty;

        final active = allCategories.where((c) => c.isActive).toList()
          ..sort((a, b) {
            final o = a.order.compareTo(b.order);
            if (o != 0) return o;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });

        final activeCategoryNames = active.map((c) => c.name).toList();
        final hasActiveCategories = activeCategoryNames.isNotEmpty;

        final selectedIsValid =
            _selectedCategory != null &&
            activeCategoryNames.contains(_selectedCategory);

        final saveDisabled =
            saving || tiersLoading || !hasAnyCategories || !hasActiveCategories;

        final isNarrow = MediaQuery.sizeOf(context).width < 600;

        final content = Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (snap.hasError)
                _Banner(
                  tone: _BannerTone.error,
                  text: 'Failed to load categories: ${snap.error}',
                ),
              if (!hasAnyCategories &&
                  snap.connectionState != ConnectionState.waiting) ...[
                const SizedBox(height: 10),
                const _Banner(
                  tone: _BannerTone.error,
                  text: 'No categories found. Please add categories first.',
                ),
              ],
              if (hasAnyCategories &&
                  !hasActiveCategories &&
                  snap.connectionState != ConnectionState.waiting) ...[
                const SizedBox(height: 10),
                const _Banner(
                  tone: _BannerTone.error,
                  text:
                      'No active categories. Activate a category in Admin → Categories.',
                ),
              ],

              Card(
                child: ListTile(
                  title: const Text('Event date & time'),
                  subtitle: Text(
                    eventDateTime == null
                        ? 'Not set'
                        : _formatDateTime(eventDateTime!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: saving ? null : _pickEventDateTime,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: _validateTitle,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: _validateNonEmpty,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedIsValid ? _selectedCategory : null,
                items: activeCategoryNames
                    .map(
                      (name) => DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
                onChanged: (!hasActiveCategories || saving)
                    ? null
                    : (v) => setState(() => _selectedCategory = v),
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (_) {
                  if (!hasAnyCategories) return 'Add categories first';
                  if (!hasActiveCategories) return 'Activate a category first';
                  final c = _selectedCategory?.trim();
                  if (c == null || c.isEmpty) return 'Required';
                  if (!activeCategoryNames.contains(c))
                    return 'Select an active category';
                  return null;
                },
              ),
              if (_selectedCategory != null &&
                  !selectedIsValid &&
                  hasActiveCategories) ...[
                const SizedBox(height: 6),
                Text(
                  'This event has a legacy/inactive category ("$_selectedCategory"). Please select an active category.',
                  style: TextStyle(color: cs.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),

              TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: _validateDescription,
              ),
              const SizedBox(height: 16),

              Text(
                'Ticket tiers',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Cheapest tier becomes the "from" price. Price 0 = Free.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              if (tiersLoading) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              for (int i = 0; i < _tiers.length; i++) _buildTierRow(i),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () {
                          if (_tiers.length >= 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Max 10 tiers')),
                            );
                            return;
                          }
                          setState(() => _tiers.add(_TierInput()));
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Add tier'),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: imageUrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: _validateUrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              if (imageUrl.text.trim().isNotEmpty) ...[
                Text(
                  'Preview',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl.text.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Text('Image preview failed'),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              SwitchListTile(
                value: popular,
                onChanged: saving
                    ? null
                    : (v) {
                        setState(() {
                          popular = v;
                          if (popular && popularRankCtrl.text.trim().isEmpty) {
                            popularRankCtrl.text = '1';
                          }
                          if (!popular) {
                            popularRankCtrl
                                .clear(); // UX; save() omits field when popular is false
                          }
                        });

                        // Re-run validation so the Popular rank field shows/hides errors correctly
                        _formKey.currentState?.validate();
                      },
                title: const Text('Popular'),
                contentPadding: EdgeInsets.zero,
              ),

              if (popular) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: popularRankCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Popular rank (1 = top)',
                    hintText: '1',
                  ),
                  validator: _validatePopularRank,
                ),
                const SizedBox(height: 6),
                Text(
                  'Lower number = higher position in Popular list.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],

              if (isNarrow) const SizedBox(height: 80),
            ],
          ),
        );

        // Desktop/tablet: WIDE AlertDialog
        if (!isNarrow) {
          final screen = MediaQuery.sizeOf(context);
          final dialogW = (screen.width - 48).clamp(720, 1040).toDouble();
          final dialogH = (screen.height - 96).clamp(560, 880).toDouble();

          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            contentPadding: EdgeInsets.zero,
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            title: Text(isEdit ? 'Edit event' : 'Add event'),
            content: SizedBox(width: dialogW, height: dialogH, child: content),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saveDisabled
                    ? null
                    : () => _save(
                        hasAnyCategories: hasAnyCategories,
                        activeCategoryNames: activeCategoryNames,
                      ),
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        }

        // Phone: fullscreen
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(isEdit ? 'Edit event' : 'Add event'),
              actions: [
                TextButton(
                  onPressed: saveDisabled
                      ? null
                      : () => _save(
                          hasAnyCategories: hasAnyCategories,
                          activeCategoryNames: activeCategoryNames,
                        ),
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: content,
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: saveDisabled
                            ? null
                            : () => _save(
                                hasAnyCategories: hasAnyCategories,
                                activeCategoryNames: activeCategoryNames,
                              ),
                        child: Text(saving ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _BannerTone { error }

class _Banner extends StatelessWidget {
  const _Banner({required this.tone, required this.text});

  final _BannerTone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = switch (tone) {
      _BannerTone.error => cs.errorContainer,
    };
    final fg = switch (tone) {
      _BannerTone.error => cs.onErrorContainer,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: fg)),
    );
  }
}
