import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

enum _CatFilter { all, active, inactive }

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _CatFilter _filter = _CatFilter.all;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('categories');

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openEditor({
    DocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CategoryEditorDialog(doc: doc),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(doc == null ? 'Category added' : 'Category updated'),
        ),
      );
    }
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final name = (doc.data()?['name'] ?? 'this category').toString();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete “$name”? This won’t update existing events that already use this category name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await doc.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Future<void> _toggleActive(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool v,
  ) async {
    try {
      await doc.reference.update({'isActive': v, 'updatedAt': Timestamp.now()});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  bool _matches(Map<String, dynamic> data) {
    final name = (data['name'] ?? '').toString().toLowerCase();
    final isActive = (data['isActive'] as bool?) ?? false;

    if (_query.isNotEmpty && !name.contains(_query)) return false;

    return switch (_filter) {
      _CatFilter.all => true,
      _CatFilter.active => isActive,
      _CatFilter.inactive => !isActive,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 720;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Add category'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search + filters card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search categories...',
                      border: const OutlineInputBorder(),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear',
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
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
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _filter == _CatFilter.all,
                          onSelected: (_) =>
                              setState(() => _filter = _CatFilter.all),
                        ),
                        ChoiceChip(
                          label: const Text('Active'),
                          selected: _filter == _CatFilter.active,
                          onSelected: (_) =>
                              setState(() => _filter = _CatFilter.active),
                        ),
                        ChoiceChip(
                          label: const Text('Inactive'),
                          selected: _filter == _CatFilter.inactive,
                          onSelected: (_) =>
                              setState(() => _filter = _CatFilter.inactive),
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
              stream: _col.orderBy('order').snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                final filtered = docs.where((d) => _matches(d.data())).toList()
                  ..sort((a, b) {
                    final ad = a.data();
                    final bd = b.data();
                    final ao = (ad['order'] as num?) ?? 0;
                    final bo = (bd['order'] as num?) ?? 0;
                    final c1 = ao.compareTo(bo);
                    if (c1 != 0) return c1;
                    final an = (ad['name'] ?? '').toString().toLowerCase();
                    final bn = (bd['name'] ?? '').toString().toLowerCase();
                    return an.compareTo(bn);
                  });

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching categories'));
                }

                // Desktop/tablet: DataTable (FULL WIDTH + no wrapping icons)
                if (!isNarrow) {
                  return LayoutBuilder(
                    builder: (context, c) {
                      return Card(
                        child: Scrollbar(
                          child: SingleChildScrollView(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                // KEY FIX: makes DataTable fill the page width
                                constraints: BoxConstraints(
                                  minWidth: c.maxWidth,
                                ),
                                child: DataTable(
                                  horizontalMargin: 16,
                                  columnSpacing: 24,
                                  headingRowHeight: 44,
                                  dataRowMinHeight: 56,
                                  dataRowMaxHeight: 72,
                                  columns: const [
                                    DataColumn(label: Text('Order')),
                                    DataColumn(label: Text('Name')),
                                    DataColumn(label: Text('Active')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: [
                                    for (final doc in filtered)
                                      _buildDataRow(context, doc),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                // Phone: card list
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final data = doc.data();
                    final name = (data['name'] ?? '').toString();
                    final order = (data['order'] as num?) ?? 0;
                    final isActive = (data['isActive'] as bool?) ?? false;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(order.toString())),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(isActive ? 'Active' : 'Inactive'),
                        trailing: Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (v) => _toggleActive(doc, v),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => _openEditor(doc: doc),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: () => _delete(doc),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        onTap: () => _openEditor(doc: doc),
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

  DataRow _buildDataRow(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    final name = (data['name'] ?? '').toString();
    final order = (data['order'] as num?) ?? 0;
    final isActive = (data['isActive'] as bool?) ?? false;

    return DataRow(
      cells: [
        DataCell(Text(order.toString())),
        DataCell(
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          onTap: () => _openEditor(doc: doc),
        ),
        DataCell(
          Switch(value: isActive, onChanged: (v) => _toggleActive(doc, v)),
        ),
        // KEY FIX: Row (not Wrap) + fixed width so it never scrambles
        DataCell(
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => _openEditor(doc: doc),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _delete(doc),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({required this.doc});

  final DocumentSnapshot<Map<String, dynamic>>? doc;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _orderCtrl;
  bool _isActive = true;

  bool _saving = false;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('categories');

  @override
  void initState() {
    super.initState();
    final data = widget.doc?.data() ?? const <String, dynamic>{};

    _nameCtrl = TextEditingController(text: (data['name'] ?? '').toString());
    _orderCtrl = TextEditingController(text: (data['order'] ?? 0).toString());
    _isActive = (data['isActive'] as bool?) ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? v) {
    final s = (v ?? '').trim();
    if (s.length < 2) return 'Name is too short';
    if (s.length > 40) return 'Name is too long';
    return null;
  }

  String? _validateOrder(String? v) {
    final s = (v ?? '').trim();
    final n = int.tryParse(s);
    if (n == null) return 'Order must be a number';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final name = _nameCtrl.text.trim();
    final order = int.parse(_orderCtrl.text.trim());
    final now = Timestamp.now();

    try {
      if (widget.doc == null) {
        await _col.add({
          'name': name,
          'order': order,
          'isActive': _isActive,
          'createdAt': now,
          'updatedAt': now,
        });
      } else {
        final createdAt = widget.doc!.data()?['createdAt'];
        await widget.doc!.reference.update({
          'name': name,
          'order': order,
          'isActive': _isActive,
          'createdAt': createdAt, // preserve (rules require it)
          'updatedAt': now,
        });
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.doc != null;
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    final content = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Music',
            ),
            validator: _validateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _orderCtrl,
            decoration: const InputDecoration(
              labelText: 'Order',
              hintText: '0',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            ],
            validator: _validateOrder,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Active'),
            subtitle: const Text(
              'Inactive categories are hidden from mobile users',
            ),
            value: _isActive,
            onChanged: _saving ? null : (v) => setState(() => _isActive = v),
          ),
          if (isNarrow) const SizedBox(height: 70),
        ],
      ),
    );

    if (!isNarrow) {
      final screen = MediaQuery.sizeOf(context);
      final dialogW = (screen.width - 48).clamp(640, 900).toDouble();
      final dialogH = (screen.height - 96).clamp(420, 700).toDouble();

      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        contentPadding: EdgeInsets.zero,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        title: Text(isEdit ? 'Edit category' : 'Add category'),
        content: SizedBox(width: dialogW, height: dialogH, child: content),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      );
    }

    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit category' : 'Add category'),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
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
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
