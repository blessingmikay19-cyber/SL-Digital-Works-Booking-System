import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booking.dart';

class BookingRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Bookings from the start of today (SAST) onwards.
  Future<List<Booking>> fetchUpcoming() async {
    final s = DateTime.now().toUtc().add(const Duration(hours: 2));
    final startOfToday =
        DateTime.utc(s.year, s.month, s.day).subtract(const Duration(hours: 2));
    final data = await _db
        .from('bookings')
        .select('id,start_time,end_time,status,notes,'
            'clients(full_name,email,phone),services(name,price)')
        .gte('start_time', startOfToday.toIso8601String())
        .order('start_time');
    return (data as List)
        .map((m) => Booking.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  /// All bookings for one client, newest first.
  Future<List<Booking>> fetchForClient(String clientId) async {
    final data = await _db
        .from('bookings')
        .select('id,start_time,end_time,status,notes,services(name,price)')
        .eq('client_id', clientId)
        .order('start_time', ascending: false);
    return (data as List)
        .map((m) => Booking.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  /// Bookings starting in [startUtc, endUtc), for the calendar.
  Future<List<Booking>> fetchBetween(DateTime startUtc, DateTime endUtc) async {
    final data = await _db
        .from('bookings')
        .select('id,start_time,end_time,status,notes,'
            'clients(full_name,email,phone),services(name,price)')
        .gte('start_time', startUtc.toIso8601String())
        .lt('start_time', endUtc.toIso8601String())
        .order('start_time');
    return (data as List)
        .map((m) => Booking.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<void> updateStatus(String id, BookingStatus status) async {
    await _db.from('bookings').update({'status': status.name}).eq('id', id);
  }

  /// Calls [onChange] whenever a booking changes. Returns a function that stops listening.
  void Function() watch(void Function() onChange) {
    final channel = _db
        .channel('bookings-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => onChange(),
        )
        .subscribe();
    return () => _db.removeChannel(channel);
  }
}
