import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/booking.dart';
import '../auth/session_view_model.dart';
import 'booking_actions.dart';
import 'booking_card.dart';
import 'bookings_view_model.dart';

class BookingsView extends StatelessWidget {
  const BookingsView({super.key});

  Future<void> _change(BuildContext context, Booking b, BookingStatus status) =>
      confirmAndChangeStatus(context, b, status, context.read<BookingsViewModel>().setStatus);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingsViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: vm.load, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => context.read<SessionViewModel>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: vm.load, child: _list(context, vm)),
    );
  }

  Widget _list(BuildContext context, BookingsViewModel vm) {
    if (vm.error != null || vm.bookings.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vm.error ?? 'No upcoming bookings.'),
        ),
      ]);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final day in vm.grouped) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text(day.key,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  for (final b in day.value)
                    BookingCard(booking: b, onAction: (s) => _change(context, b, s)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
