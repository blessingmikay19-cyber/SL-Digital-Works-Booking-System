import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/formatters.dart';
import '../../data/models/booking.dart';
import '../bookings/booking_actions.dart';
import '../bookings/booking_card.dart';
import 'calendar_view_model.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final primary = Theme.of(context).colorScheme.primary;
    final selected = vm.selectedBookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(tooltip: 'Today', onPressed: vm.goToday, icon: const Icon(Icons.today)),
          IconButton(tooltip: 'Refresh', onPressed: vm.load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCE3DF)),
                        ),
                        child: TableCalendar<Booking>(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2032, 12, 31),
                          focusedDay: vm.focusedDay,
                          currentDay: vm.today,
                          calendarFormat: _format,
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                            CalendarFormat.week: 'Week',
                          },
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          selectedDayPredicate: (d) => isSameDay(d, vm.selectedDay),
                          eventLoader: vm.eventsFor,
                          onDaySelected: vm.selectDay,
                          onPageChanged: vm.changePage,
                          onFormatChanged: (f) => setState(() => _format = f),
                          headerStyle: const HeaderStyle(titleCentered: true),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                            todayTextStyle: const TextStyle(color: Color(0xFF172E2B)),
                            selectedDecoration:
                                BoxDecoration(color: primary, shape: BoxShape.circle),
                            markerDecoration:
                                BoxDecoration(color: primary, shape: BoxShape.circle),
                            markersMaxCount: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(dayLabel(vm.selectedDay),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      if (vm.error != null)
                        Text(vm.error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
                      else if (selected.isEmpty)
                        const Text('No bookings on this day.',
                            style: TextStyle(color: Color(0xFF5B6C68))),
                      for (final b in selected)
                        BookingCard(
                          booking: b,
                          onAction: (s) => confirmAndChangeStatus(context, b, s, vm.setStatus),
                        ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
