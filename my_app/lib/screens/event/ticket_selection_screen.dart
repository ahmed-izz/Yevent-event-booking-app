import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event.dart';
import '../../theme/app_radii.dart';
import '../../widgets/primary_button.dart';
import 'checkout_screen.dart';

class TicketSelectionScreen extends StatefulWidget {
  const TicketSelectionScreen({super.key, required this.event});

  static const routeName = 'ticketSelection';
  static const routePath = '/ticket-selection';

  final Event event;

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _Tier {
  const _Tier({required this.name, required this.priceYER});
  final String name;
  final int priceYER;
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  final Map<String, int> _qty = {}; // tierName -> qty

  String _money(int value) {
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => ',');
  }

  List<_Tier> _parseTiers(Map<String, dynamic>? data) {
    final raw = data?['tiers'];

    if (raw is List) {
      final tiers = <_Tier>[];
      for (final item in raw) {
        if (item is Map) {
          final name = (item['name'] ?? '').toString().trim();
          final pRaw = item['priceYER'];
          final price = (pRaw is num) ? pRaw.toInt() : int.tryParse('$pRaw') ?? 0;
          if (name.isNotEmpty) tiers.add(_Tier(name: name, priceYER: price));
        }
      }
      if (tiers.isNotEmpty) return tiers;
    }

    // Fallback for old events: single tier using priceFromYER
    return [
      _Tier(name: 'General', priceYER: widget.event.priceFromYER),
    ];
  }

  int _totalFor(List<_Tier> tiers) {
    var sum = 0;
    for (final t in tiers) {
      sum += (_qty[t.name] ?? 0) * t.priceYER;
    }
    return sum;
  }

  int _totalQtyFor(List<_Tier> tiers) {
    var sum = 0;
    for (final t in tiers) {
      sum += (_qty[t.name] ?? 0);
    }
    return sum;
  }

  void _syncQtyKeys(List<_Tier> tiers) {
    final names = tiers.map((t) => t.name).toSet();
    _qty.removeWhere((k, _) => !names.contains(k));
    for (final t in tiers) {
      _qty.putIfAbsent(t.name, () => 0);
    }
  }

  void _goCheckout(List<_Tier> tiers) {
    final lines = <TierOrderLine>[];
    for (final t in tiers) {
      final q = _qty[t.name] ?? 0;
      if (q > 0) {
        lines.add(TierOrderLine(name: t.name, unitPriceYER: t.priceYER, quantity: q));
      }
    }

    final totalQty = lines.fold<int>(0, (a, b) => a + b.quantity);
    if (totalQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least 1 ticket')),
      );
      return;
    }

    context.push(
      CheckoutScreen.routePath,
      extra: CheckoutPayload(
        event: widget.event,
        lines: lines,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final eventDocStream = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: eventDocStream,
      builder: (context, snap) {
        final data = snap.data?.data();
        final tiers = _parseTiers(data);

        // keep qty keys in sync with tiers
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _syncQtyKeys(tiers));
        });

        final total = _totalFor(tiers);
        final totalQty = _totalQtyFor(tiers);
        final isFree = total == 0;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            title: const Text('Select Tickets'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            children: [
              // Event summary
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.event.dateLabel} • ${widget.event.location}',
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

              const SizedBox(height: 16),
              Text('Choose tier(s)', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),

              for (final t in tiers) ...[
                _TierCard(
                  title: t.name,
                  subtitle: 'Select quantity',
                  priceText: t.priceYER <= 0 ? 'Free' : '${_money(t.priceYER)} YR',
                  qty: _qty[t.name] ?? 0,
                  onMinus: () => setState(() => _qty[t.name] = ((_qty[t.name] ?? 0) - 1).clamp(0, 99)),
                  onPlus: () => setState(() => _qty[t.name] = ((_qty[t.name] ?? 0) + 1).clamp(0, 99)),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),

          // Sticky summary + CTA
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
                        Text(
                          totalQty == 0 ? 'Total' : 'Total • $totalQty ticket(s)',
                          style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFree ? 'Free' : '${_money(total)} YR',
                          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Next: Checkout',
                      onPressed: () => _goCheckout(tiers),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.title,
    required this.subtitle,
    required this.priceText,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final String title;
  final String subtitle;
  final String priceText;
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final selected = qty > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? cs.primary.withOpacity(0.08) : cs.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: selected ? cs.primary.withOpacity(0.35) : cs.outlineVariant.withOpacity(0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: cs.primary.withOpacity(0.25)),
                          ),
                          child: Text(
                            'Selected',
                            style: tt.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Text(priceText, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _QtyStepper(qty: qty, onMinus: onMinus, onPlus: onPlus),
          ],
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.qty, required this.onMinus, required this.onPlus});

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            onPressed: qty == 0 ? null : onMinus,
            icon: const Icon(Icons.remove),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 22,
            child: Text('$qty',
                textAlign: TextAlign.center,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            onPressed: onPlus,
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}