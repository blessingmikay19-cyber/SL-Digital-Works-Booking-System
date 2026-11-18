import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/models/booking.dart';
import '../widgets/status_chip.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, required this.onAction});

  final Booking booking;
  final void Function(BookingStatus status) onAction;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    const muted = TextStyle(color: Color(0xFF5B6C68));
    final open = b.status == BookingStatus.pending || b.status == BookingStatus.confirmed;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDCE3DF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('${hm(b.start)}–${hm(b.end)}  ${b.serviceName}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              StatusChip(b.status),
            ]),
            const SizedBox(height: 8),
            Text('${b.clientName} · ${b.clientEmail}'),
            if (b.clientPhone.isNotEmpty) Text(b.clientPhone),
            Text(b.price > 0 ? 'R${b.price}' : 'Free', style: muted),
            if (b.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${b.notes}', style: muted),
            ],
            if (open) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [
                if (b.status == BookingStatus.pending)
                  FilledButton(
                      onPressed: () => onAction(BookingStatus.confirmed),
                      child: const Text('Confirm')),
                if (b.status == BookingStatus.confirmed)
                  FilledButton(
                      onPressed: () => onAction(BookingStatus.completed),
                      child: const Text('Complete')),
                OutlinedButton(
                    onPressed: () => onAction(BookingStatus.cancelled),
                    child: const Text('Cancel')),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
