import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'ticket_selection_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({super.key, required this.event});

  static const routeName = 'eventDetails';
  static const routePath = '/event-details';

  final Event event;

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<AppState>().isFavorite(event.id);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            onPressed: () => context.read<AppState>().toggleFavorite(event),
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(event.imageUrl, height: 200, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(event.dateText, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(event.location, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          const Text('Category', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(event.category),
          const SizedBox(height: 14),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(event.description),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('from ${event.priceFromYER} YR',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: PrimaryButton(
                  text: 'Book Ticket',
                  onPressed: () => context.push(TicketSelectionScreen.routePath, extra: event),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}