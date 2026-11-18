import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/models/booking.dart';

/// Changes a booking's status. Cancelling asks for confirmation first, and a
/// failed update shows a message. Shared by the Bookings and Calendar screens.
Future<void> confirmAndChangeStatus(
  BuildContext context,
  Booking booking,
  BookingStatus status,
  Future<bool> Function(Booking, BookingStatus) apply,
) async {
  if (status == BookingStatus.cancelled) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
            '${booking.clientName}, ${dayLabel(booking.start)} at ${hm(booking.start)}.\n'
            'The client will be emailed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancel booking')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  final done = await apply(booking, status);
  if (!done && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Could not update the booking.')));
  }
}
