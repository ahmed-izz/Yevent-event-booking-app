import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event.dart';
import '../../theme/app_colors.dart';
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

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  int vipQty = 1;
  int goldQty = 0;
  int silverQty = 0;

  int get total =>
      vipQty * 10000 +
      goldQty * 5000 +
      silverQty * 3000;

  void _goCheckout() {
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 1 ticket')));
      return;
    }

    // pick a simple "main tier" (priority VIP > Gold > Silver)
    final tier = vipQty > 0 ? 'VIP' : (goldQty > 0 ? 'Gold' : 'Silver');
    final qty = vipQty > 0 ? vipQty : (goldQty > 0 ? goldQty : silverQty);

    final payload = CheckoutPayload(
      event: widget.event,
      tier: tier,
      quantity: qty,
      totalYER: total,
    );

    context.push(CheckoutScreen.routePath, extra: payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Select Tickets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _tierRow(
              title: 'VIP',
              price: '10,000 YR',
              qty: vipQty,
              onMinus: () => setState(() => vipQty = (vipQty - 1).clamp(0, 99)),
              onPlus: () => setState(() => vipQty = (vipQty + 1).clamp(0, 99)),
            ),
            const SizedBox(height: 10),
            _tierRow(
              title: 'Gold',
              price: '5,000 YR',
              qty: goldQty,
              onMinus: () => setState(() => goldQty = (goldQty - 1).clamp(0, 99)),
              onPlus: () => setState(() => goldQty = (goldQty + 1).clamp(0, 99)),
            ),
            const SizedBox(height: 10),
            _tierRow(
              title: 'Silver',
              price: '3,000 YR',
              qty: silverQty,
              onMinus: () => setState(() => silverQty = (silverQty - 1).clamp(0, 99)),
              onPlus: () => setState(() => silverQty = (silverQty + 1).clamp(0, 99)),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Total: $total YR', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            PrimaryButton(text: 'Next: Checkout', onPressed: _goCheckout),
          ],
        ),
      ),
    );
  }

  Widget _tierRow({
    required String title,
    required String price,
    required int qty,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(price, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)),
            Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800)),
            IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline)),
          ],
        ),
      ),
    );
  }
}