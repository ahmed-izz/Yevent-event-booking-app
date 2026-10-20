import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../state/app_state.dart';
import '../../theme/app_radii.dart';
import '../../widgets/primary_button.dart';
import 'ticket_selection_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  /// Shareable route: /event/<id>
  static const routeName = 'eventDetails';
  static const routePattern = '/event/:id';
  static String routeForId(String id) => '/event/$id';

  /// Legacy route (extra-based): /event-details
  static const legacyRoutePath = '/event-details';

  @Deprecated(
    'Use routeForId(id) so Event Details is refresh/share-safe on web.',
  )
  static const routePath = legacyRoutePath;

  final String eventId;

  /// If navigating inside the app, passing the event avoids a loading spinner.
  final Event? initialEvent;

  factory EventDetailsScreen.fromEvent(Event event) {
    return EventDetailsScreen(eventId: event.id, initialEvent: event);
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('events').doc(eventId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        // Start with initialEvent (fast), then replace with Firestore (fresh).
        Event? event = initialEvent;

        if (snap.hasError) {
          return _ScaffoldMessage(
            title: 'Event',
            message: 'Failed to load event.\n\n${snap.error}',
          );
        }

        if (snap.hasData) {
          final doc = snap.data!;
          if (!doc.exists) {
            return const _ScaffoldMessage(
              title: 'Event',
              message: 'This event no longer exists (or was removed).',
            );
          }
          event = Event.fromFirestore(doc);
        }

        if (event == null) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        return _EventDetailsBody(event: event);
      },
    );
  }
}

class _EventDetailsBody extends StatelessWidget {
  const _EventDetailsBody({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isFav = context.watch<AppState>().isFavorite(event.id);

    final isFree = event.priceFromYER <= 0;
    final priceText = isFree ? 'Free' : '${event.priceFromYER} YER';

    final hasTime = event.timeLabel.trim().isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 280,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton.filledTonal(
                tooltip: isFav ? 'Remove favorite' : 'Add favorite',
                onPressed: () => context.read<AppState>().toggleFavorite(event),
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _HeroImage(url: event.imageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                          Colors.black.withOpacity(0.35),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  event.title,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),

                // Small, readable subtitle (helps users quickly see when it starts)
                if (event.hasKnownDate) ...[
                  const SizedBox(height: 6),
                  Text(
                    hasTime
                        ? '${event.dateLabel} • ${event.timeLabel}'
                        : event.dateLabel,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_month,
                      text: event.dateLabel,
                    ),

                    // NEW: show time on details (important for booking decision)
                    if (hasTime)
                      _InfoChip(icon: Icons.schedule, text: event.timeLabel),

                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      text: event.location,
                    ),
                    _InfoChip(
                      icon: Icons.local_offer_outlined,
                      text: event.category,
                    ),

                    // Optional: highlight popular (fits existing theme style)
                    if (event.popular)
                      const _InfoChip(
                        icon: Icons.local_fire_department_outlined,
                        text: 'Popular',
                      ),
                  ],
                ),
                const SizedBox(height: 18),

                Text(
                  'Description',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  event.description.trim().isEmpty
                      ? 'No description provided.'
                      : event.description.trim(),
                  style: tt.bodyMedium?.copyWith(
                    height: 1.35,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),

                // Price callout (keeps your current look, just slightly clearer)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payments_outlined, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isFree ? 'Free entry' : 'Tickets from $priceText',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
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
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFree ? 'Entry' : 'From',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priceText,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: isFree ? 'Get Ticket' : 'Book Ticket',
                  onPressed: () => context.push(
                    TicketSelectionScreen.routePath,
                    extra: event,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScaffoldMessage extends StatelessWidget {
  const _ScaffoldMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            message,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return Container(
        color: Colors.black12,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, size: 40),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url.trim(),
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: Colors.black12),
      errorWidget: (_, __, ___) => Container(
        color: Colors.black12,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
      ),
    );
  }
}
