import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.compact = false,
  });

  final Event event;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isFav = context.watch<AppState>().isFavorite(event.id);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: compact ? _compact(context, isFav) : _big(context, isFav),
      ),
    );
  }

  Widget _big(BuildContext context, bool isFav) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Image.network(event.imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover),
            Positioned(
              right: 10,
              top: 10,
              child: IconButton(
                onPressed: () => context.read<AppState>().toggleFavorite(event),
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(event.dateText, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _compact(BuildContext context, bool isFav) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(event.imageUrl, width: 54, height: 54, fit: BoxFit.cover),
      ),
      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(event.dateText, style: const TextStyle(color: AppColors.muted)),
      trailing: IconButton(
        onPressed: () => context.read<AppState>().toggleFavorite(event),
        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : null),
      ),
    );
  }
}