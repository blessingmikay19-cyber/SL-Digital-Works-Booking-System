import 'package:flutter/foundation.dart';

import '../../core/formatters.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';

/// Days are calendar days in South Africa, held as UTC-midnight dates
/// (the format the calendar widget uses).
class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel(this._repo) {
    final n = toSast(DateTime.now());
    today = DateTime.utc(n.year, n.month, n.day);
    focusedDay = today;
    selectedDay = today;
    _stopWatching = _repo.watch(load);
    load();
  }

  final BookingRepository _repo;
  late final void Function() _stopWatching;
  bool _disposed = false;

  late final DateTime today;
  late DateTime focusedDay;
  late DateTime selectedDay;
  Map<DateTime, List<Booking>> _byDay = {};
  bool loading = true;
  String? error;

  static DateTime _key(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Bookings that should show a dot on [day] (cancelled ones are left out).
  List<Booking> eventsFor(DateTime day) => (_byDay[_key(day)] ?? const <Booking>[])
      .where((b) => b.status != BookingStatus.cancelled)
      .toList();

  /// Everything on the selected day, including cancelled bookings.
  List<Booking> get selectedBookings => _byDay[_key(selectedDay)] ?? const <Booking>[];

  void selectDay(DateTime selected, DateTime focused) {
    selectedDay = _key(selected);
    focusedDay = _key(focused);
    _notify();
  }

  void changePage(DateTime focused) {
    focusedDay = _key(focused);
    load();
  }

  void goToday() {
    selectedDay = today;
    focusedDay = today;
    load();
  }

  /// Loads the focused month plus the month either side.
  Future<void> load() async {
    try {
      const offset = Duration(hours: 2); // SAST is UTC+2
      final f = focusedDay;
      final from = DateTime.utc(f.year, f.month - 1, 1).subtract(offset);
      final to = DateTime.utc(f.year, f.month + 2, 1).subtract(offset);
      final list = await _repo.fetchBetween(from, to);
      final map = <DateTime, List<Booking>>{};
      for (final b in list) {
        map.putIfAbsent(_key(b.start), () => []).add(b);
      }
      _byDay = map;
      error = null;
    } catch (_) {
      error = 'Could not load bookings.';
    }
    loading = false;
    _notify();
  }

  /// Returns false if the update failed.
  Future<bool> setStatus(Booking booking, BookingStatus status) async {
    try {
      await _repo.updateStatus(booking.id, status);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopWatching();
    super.dispose();
  }
}
