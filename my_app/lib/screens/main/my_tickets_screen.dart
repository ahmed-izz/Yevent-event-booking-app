import 'package:barcode_widget/barcode_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTicketDetails(BuildContext context, _TicketDoc t) {
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ticket details',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _kv('Ticket ID', t.id),
              _kv('Event', t.eventTitle),
              _kv('Type', t.ticketType),
              _kv('Name', t.buyerName),
              _kv('Email', t.buyerEmail),
              _kv('Phone', t.buyerPhone),
              _kv('Status', t.status),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return SafeArea(
        child: Center(
          child: Text(
            'Please log in to view your tickets.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final stream = FirebaseFirestore.instance
    .collection('tickets')
    .where('uid', isEqualTo: user.uid)
    .orderBy('createdAt', descending: true)
    .snapshots();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Tickets',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _InlineMessage(
                      text: 'Failed to load tickets: ${snap.error}',
                      color: cs.error,
                    );
                  }

                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = snap.data?.docs ?? const [];
                  final tickets = docs
                      .map((d) => _TicketDoc.fromDoc(d))
                      .toList();

                  if (tickets.isEmpty) {
                    return _EmptyStateCard(
                      text:
                          'No tickets booked yet.\n\nWhen you book an event, your tickets will appear here.',
                      icon: Icons.confirmation_number_outlined,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              '${tickets.length} ticket(s)',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 520,
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: tickets.length,
                          itemBuilder: (context, i) {
                            final t = tickets[i];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _TicketCard(
                                t: t,
                                onTap: () => _showTicketDetails(context, t),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketDoc {
  _TicketDoc({
    required this.id,
    required this.createdAt,
    required this.eventTitle,
    required this.eventImageUrl,
    required this.eventDate,
    required this.location,
    required this.ticketType,
    required this.unitPriceYER,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.status,
    required this.ticketIndex,
    required this.ticketCount,
  });

  final String id;
  final DateTime createdAt;

  final String eventTitle;
  final String eventImageUrl;
  final DateTime eventDate;
  final String location;

  final String ticketType;
  final int unitPriceYER;

  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;

  final String status;

  final int? ticketIndex;
  final int? ticketCount;

  static _TicketDoc fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};

    DateTime toDt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    int toInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    return _TicketDoc(
      id: doc.id,
      createdAt: toDt(d['createdAt']),
      eventTitle: (d['eventTitle'] ?? '').toString(),
      eventImageUrl: (d['eventImageUrl'] ?? '').toString(),
      eventDate: toDt(d['eventDate']),
      location: (d['location'] ?? '').toString(),
      ticketType: (d['ticketType'] ?? '').toString(),
      unitPriceYER: toInt(d['unitPriceYER']),
      buyerName: (d['buyerName'] ?? '').toString(),
      buyerEmail: (d['buyerEmail'] ?? '').toString(),
      buyerPhone: (d['buyerPhone'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      ticketIndex:
          d['ticketIndex'] is num ? (d['ticketIndex'] as num).toInt() : null,
      ticketCount:
          d['ticketCount'] is num ? (d['ticketCount'] as num).toInt() : null,
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.t, required this.onTap});

  final _TicketDoc t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateStr =
        MaterialLocalizations.of(context).formatMediumDate(t.eventDate);
    final timeStr = TimeOfDay.fromDateTime(t.eventDate).format(context);

    final priceStr = t.unitPriceYER <= 0 ? 'Free' : '${t.unitPriceYER} YR';
    final idxStr = (t.ticketIndex != null && t.ticketCount != null)
        ? '${t.ticketIndex}/${t.ticketCount}'
        : null;

    // Better dark-mode look than using cs.primary for the whole panel
    final panelColor = isDark ? cs.primaryContainer : cs.primary;
    final onPanel = isDark ? cs.onPrimaryContainer : cs.onPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Material(
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        color: cs.surface,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: t.eventImageUrl.trim().isEmpty
                    ? Container(
                        color: cs.surfaceVariant,
                        child: const Center(
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: t.eventImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: cs.surfaceVariant),
                        errorWidget: (_, __, ___) => Container(
                          color: cs.surfaceVariant,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: panelColor,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.eventTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: onPanel,
                              ),
                            ),
                          ),
                          if (idxStr != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: onPanel.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: onPanel.withOpacity(0.22),
                                ),
                              ),
                              child: Text(
                                idxStr,
                                style: tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: onPanel,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: onPanel.withOpacity(0.22), height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TicketInfo(
                              label: 'Date',
                              value: dateStr,
                              color: onPanel,
                            ),
                          ),
                          Expanded(
                            child: _TicketInfo(
                              label: 'Time',
                              value: timeStr,
                              color: onPanel,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _TicketInfo(
                              label: 'Location',
                              value: t.location,
                              color: onPanel,
                            ),
                          ),
                          Expanded(
                            child: _TicketInfo(
                              label: 'Type',
                              value: t.ticketType,
                              color: onPanel,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        priceStr,
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: onPanel,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // FIX: Always show barcode as black on white (scannable in dark mode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: t.id,
                          drawText: false,
                          height: 64,
                          color: Colors.black,
                        ),
                      ),
                    ],
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

class _TicketInfo extends StatelessWidget {
  const _TicketInfo({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: color.withOpacity(0.85),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String text;
  final IconData icon;

  const _EmptyStateCard({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final String text;
  final Color color;

  const _InlineMessage({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(text, style: tt.bodyMedium?.copyWith(color: color)),
    );
  }
}