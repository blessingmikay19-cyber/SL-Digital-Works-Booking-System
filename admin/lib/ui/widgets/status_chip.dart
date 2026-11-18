import 'package:flutter/material.dart';

import '../../data/models/booking.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final BookingStatus status;

  static const _colors = {
    BookingStatus.pending: Color(0xFF875F16),
    BookingStatus.confirmed: Color(0xFF286640),
    BookingStatus.completed: Color(0xFF5B6C68),
    BookingStatus.cancelled: Color(0xFFAF3D35),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(status.name,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}
