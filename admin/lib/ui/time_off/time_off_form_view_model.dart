import 'package:flutter/foundation.dart';

import '../../data/repositories/blocked_time_repository.dart';

class TimeOffFormViewModel extends ChangeNotifier {
  TimeOffFormViewModel(this._repo);

  final BlockedTimeRepository _repo;
  bool _disposed = false;

  bool saving = false;
  String? error;

  /// Dates are calendar days; times are minutes after midnight, all in South Africa time.
  Future<bool> save({
    required DateTime startDate,
    required DateTime endDate,
    required bool allDay,
    required int startMinutes,
    required int endMinutes,
    required String reason,
  }) async {
    // South African wall-clock time, held in a UTC DateTime for arithmetic.
    DateTime wall(DateTime d, int minutes) =>
        DateTime.utc(d.year, d.month, d.day).add(Duration(minutes: minutes));

    final start = wall(startDate, allDay ? 0 : startMinutes);
    final end = allDay
        ? wall(endDate, 0).add(const Duration(days: 1))
        : wall(endDate, endMinutes);

    if (!end.isAfter(start)) {
      error = 'The end must be after the start.';
      _notify();
      return false;
    }
    saving = true;
    error = null;
    _notify();
    try {
      // SAST is UTC+2, so subtract 2 hours to get the real UTC instant.
      const offset = Duration(hours: 2);
      await _repo.add(start.subtract(offset), end.subtract(offset), reason.trim());
      saving = false;
      _notify();
      return true;
    } catch (_) {
      saving = false;
      error = 'Could not save. Please try again.';
      _notify();
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
