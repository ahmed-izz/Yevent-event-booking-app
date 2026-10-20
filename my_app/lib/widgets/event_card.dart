import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:my_app/models/event.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.compact,
    this.rank,
    this.trailing,
  });

  final Event event;
  final VoidCallback onTap;
  final bool compact;

  /// Optional: show ranking badge (#1, #2, #3...) on compact cards.
  final int? rank;

  /// Optional: custom trailing widget for compact cards (e.g. favorite button).
  /// If null, a chevron is shown.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactEventCard(
            event: event,
            onTap: onTap,
            rank: rank,
            trailing: trailing,
          )
        : _LargeEventCard(event: event, onTap: onTap);
  }
}

class _LargeEventCard extends StatelessWidget {
  const _LargeEventCard({required this.event, required this.onTap});

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const radius = 18.0;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2.2,
      shadowColor: cs.shadow.withOpacity(0.14),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 162,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _EventImage(url: event.imageUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.06),
                          Colors.black.withOpacity(0.00),
                          Colors.black.withOpacity(0.34),
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  if (event.popular)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _Pill(
                        text: 'Popular',
                        background: cs.primary.withOpacity(0.92),
                        foreground: cs.onPrimary,
                        border: cs.primary.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEventCard extends StatelessWidget {
  const _CompactEventCard({
    required this.event,
    required this.onTap,
    required this.rank,
    required this.trailing,
  });

  final Event event;
  final VoidCallback onTap;
  final int? rank;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1.8,
      shadowColor: cs.shadow.withOpacity(0.12),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 78,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 74,
                    height: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _EventImage(url: event.imageUrl),
                        if (rank != null)
                          Positioned(
                            left: 6,
                            top: 6,
                            child: _RankBadge(rank: rank!),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.dateLabel} • ${event.location}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  child: Center(
                    child:
                        trailing ??
                        Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
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

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  Color _bg() {
    if (rank == 1) return const Color(0xFFFFD54F); // gold
    if (rank == 2) return const Color(0xFFCFD8DC); // silver
    if (rank == 3) return const Color(0xFFBCAAA4); // bronze
    return Colors.black.withOpacity(0.65);
  }

  Color _fg(Color bg) {
    // Auto-pick readable text color
    return bg.computeLuminance() < 0.5 ? Colors.white : Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bg();
    final fg = _fg(bg);

    return Material(
      color: bg,
      elevation: 2.0,
      shadowColor: Colors.black.withOpacity(0.22),
      surfaceTintColor: Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(color: Colors.black.withOpacity(0.18), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '#$rank',
          style: TextStyle(
            color: fg, // <-- FIX
            fontWeight: FontWeight.w900,
            fontSize: 12,
            height: 1.0,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (url.trim().isEmpty) {
      return Container(
        color: cs.surfaceVariant.withOpacity(0.6),
        child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, __) =>
          Container(color: cs.surfaceVariant.withOpacity(0.6)),
      errorWidget: (_, __, ___) => Container(
        color: cs.surfaceVariant.withOpacity(0.6),
        child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
    required this.border,
    this.dense = false,
  });

  final String text;
  final Color background;
  final Color foreground;
  final Color border;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (dense ? tt.labelSmall : tt.labelMedium)?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
