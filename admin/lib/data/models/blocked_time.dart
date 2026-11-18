import '../../core/formatters.dart';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class BlockedTime {
  BlockedTime({required this.id, required this.start, required this.end, required this.reason});

  final String id;
  final DateTime start; // SAST wall-clock time
  final DateTime end;
  final String reason;

  bool get isLunch => reason == 'Lunch';

  /// Human-readable range, e.g. "Fri, 20 Nov 2026 · 12:00–13:00" or "... · All day".
  String get label {
    final allDay = start.hour == 0 && start.minute == 0 && end.hour == 0 && end.minute == 0;
    if (allDay) {
      final last = end.subtract(const Duration(days: 1));
      return _sameDay(start, last)
          ? '${dayLabel(start)} · All day'
          : '${dayLabel(start)} → ${dayLabel(last)} · All day';
    }
    return _sameDay(start, end)
        ? '${dayLabel(start)} · ${hm(start)}–${hm(end)}'
        : '${dayLabel(start)} ${hm(start)} → ${dayLabel(end)} ${hm(end)}';
  }

  factory BlockedTime.fromMap(Map<String, dynamic> m) => BlockedTime(
        id: m['id'] as String,
        start: toSast(DateTime.parse(m['start_time'] as String)),
        end: toSast(DateTime.parse(m['end_time'] as String)),
        reason: (m['reason'] ?? '') as String,
      );
}
