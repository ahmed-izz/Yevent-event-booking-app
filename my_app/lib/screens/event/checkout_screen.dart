import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../models/ticket.dart';
import '../../state/app_state.dart';
import '../../widgets/primary_button.dart';
import '../main/main_screen.dart';

class CheckoutPayload {
  final Event event;
  final String tier;
  final int quantity;
  final int totalYER;

  CheckoutPayload({
    required this.event,
    required this.tier,
    required this.quantity,
    required this.totalYER,
  });
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key, required this.payload});

  static const routeName = 'checkout';
  static const routePath = '/checkout';

  final CheckoutPayload payload;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Confirm & Pay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payload.event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(payload.event.dateText),
            const SizedBox(height: 12),
            Text('Tier: ${payload.tier}'),
            Text('Quantity: ${payload.quantity}'),
            const SizedBox(height: 12),
            Text('Total: ${payload.totalYER} YR', style: const TextStyle(fontWeight: FontWeight.w900)),
            const Spacer(),
            PrimaryButton(
              text: 'Confirm (Mock Payment)',
              onPressed: () {
                final ticket = Ticket(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  eventId: payload.event.id,
                  eventTitle: payload.event.title,
                  tier: payload.tier,
                  quantity: payload.quantity,
                  totalYER: payload.totalYER,
                  dateText: payload.event.dateText,
                );

                context.read<AppState>().addTicket(ticket);

                // go to tickets tab
                context.go('${MainScreen.routePath}?tab=tickets');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booked successfully (mock)')));
              },
            )
          ],
        ),
      ),
    );
  }
}