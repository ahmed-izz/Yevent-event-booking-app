import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event.dart';
import '../../theme/app_radii.dart';
import '../../widgets/primary_button.dart';
import '../main/main_screen.dart';

class TierOrderLine {
  final String name;
  final int unitPriceYER;
  final int quantity;

  const TierOrderLine({
    required this.name,
    required this.unitPriceYER,
    required this.quantity,
  });

  int get lineTotal => unitPriceYER * quantity;
}

class CheckoutPayload {
  final Event event;
  final List<TierOrderLine> lines;

  CheckoutPayload({
    required this.event,
    required this.lines,
  });

  int get totalQty => lines.fold<int>(0, (a, b) => a + b.quantity);
  int get totalYER => lines.fold<int>(0, (a, b) => a + b.lineTotal);
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.payload});

  static const routeName = 'checkout';
  static const routePath = '/checkout';

  final CheckoutPayload payload;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  bool _saving = false;

  String _money(int value) {
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ',');
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _confirm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = widget.payload;

    final totalTickets = payload.totalQty;
    if (totalTickets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tickets selected')),
      );
      return;
    }

    final ed = payload.event.eventDate; // DateTime (non-null)

    setState(() => _saving = true);

    final ticketsCol = FirebaseFirestore.instance.collection('tickets');
    final purchaseId = ticketsCol.doc().id;

    try {
      final batch = FirebaseFirestore.instance.batch();

      var ticketIndex = 0;
      for (final line in payload.lines) {
        for (int i = 0; i < line.quantity; i++) {
          ticketIndex++;

          final ref = ticketsCol.doc(); // each doc is 1 ticket
          batch.set(ref, {
            'uid': user.uid,
            'purchaseId': purchaseId,

            'eventId': payload.event.id,
            'eventTitle': payload.event.title,
            'eventImageUrl': payload.event.imageUrl,
            'eventDate': Timestamp.fromDate(ed),
            'location': payload.event.location,

            'ticketType': line.name,
            'unitPriceYER': line.unitPriceYER,

            'buyerName': _nameCtrl.text.trim(),
            'buyerEmail': _emailCtrl.text.trim(),
            'buyerPhone': _phoneCtrl.text.trim(),

            'status': 'confirmed',
            'createdAt': FieldValue.serverTimestamp(),

            // optional helpers for UI
            'ticketIndex': ticketIndex,
            'ticketCount': totalTickets,
          });
        }
      }

      await batch.commit();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PurchaseSuccessDialog(
          eventTitle: payload.event.title,
          count: totalTickets,
        ),
      );

      if (!mounted) return;
      context.go('${MainScreen.routePath}?tab=tickets');
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Purchase failed')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final payload = widget.payload;
    final totalText = payload.totalYER <= 0 ? 'Free' : '${_money(payload.totalYER)} YR';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Checkout'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Text('Your details', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: _req,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _req,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: _req,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                Icon(Icons.confirmation_number_outlined, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payload.event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${payload.event.dateLabel} • ${payload.event.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Text('Order details', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),

          for (final line in payload.lines) ...[
            _InfoRow(
              label: '${line.name} × ${line.quantity}',
              value: line.lineTotal <= 0 ? 'Free' : '${_money(line.lineTotal)} YR',
            ),
            const SizedBox(height: 8),
          ],

          _InfoRow(
            label: 'Payment',
            value: payload.totalYER <= 0 ? 'Free' : 'Mock payment (demo)',
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Total', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                ),
                Text(
                  totalText,
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: cs.primary.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    payload.totalYER <= 0
                        ? 'This event is free. Tickets will be issued immediately.'
                        : 'This is a demo checkout. No real payment is processed.',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.7))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(totalText, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: _saving
                      ? 'Confirming...'
                      : (payload.totalYER <= 0 ? 'Confirm (Free)' : 'Confirm (Mock Payment)'),
                  onPressed: _saving ? null : _confirm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(value, style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _PurchaseSuccessDialog extends StatelessWidget {
  const _PurchaseSuccessDialog({required this.eventTitle, required this.count});

  final String eventTitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.verified_rounded, color: cs.primary),
          const SizedBox(width: 8),
          const Text('Confirmed'),
        ],
      ),
      content: Text(
        'You received $count ticket(s) for:\n\n$eventTitle',
        style: tt.bodyMedium,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('View My Tickets'),
        ),
      ],
    );
  }
}