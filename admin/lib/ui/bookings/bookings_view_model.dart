import 'package:flutter/foundation.dart';

import '../../core/formatters.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';

class BookingsViewModel extends ChangeNotifier {
  BookingsViewModel(this._repo) {
    _stopWatching = _repo.watch(load);
    load();
  }

  final BookingRepository _repo;
  late final void Function() _stopWatching;
  bool _disposed = false;

  List<Booking> bookings = [];
  bool loading = true;
  String? error;

  /// Bookings grouped by day, in order.
  List<MapEntry<String, List<Booking>>> get grouped {
    final map = <String, List<Booking>>{};
    for (final b in bookings) {
      map.putIfAbsent(dayLabel(b.start), () => []).add(b);
    }
    return map.entries.toList();
  }

  Future<void> load() async {
    try {
      bookings = await _repo.fetchUpcoming();
      error = null;
    } catch (_) {
      error = 'Could not load bookings. Pull down to retry.';
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
