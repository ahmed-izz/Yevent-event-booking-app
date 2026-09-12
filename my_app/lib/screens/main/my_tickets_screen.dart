import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tickets = context.watch<AppState>().tickets;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('My Tickets', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          if (tickets.isEmpty)
            const Text('No tickets booked yet.')
          else
            ...tickets.map(
              (t) => Card(
                child: ListTile(
                  title: Text(t.eventTitle),
                  subtitle: Text('${t.tier} • Qty ${t.quantity} • ${t.dateText}'),
                  trailing: Text('${t.totalYER} YR'),
                ),
              ),
            )
        ],
      ),
    );
  }
}