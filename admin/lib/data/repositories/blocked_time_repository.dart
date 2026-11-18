import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/blocked_time.dart';

class BlockedTimeRepository {
  final SupabaseClient _db = Supabase.instance.client;

  /// Blocks that have not finished yet.
  Future<List<BlockedTime>> fetchUpcoming() async {
    final data = await _db
        .from('blocked_times')
        .select('id,start_time,end_time,reason')
        .gte('end_time', DateTime.now().toUtc().toIso8601String())
        .order('start_time');
    return (data as List)
        .map((m) => BlockedTime.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  /// [startUtc] and [endUtc] must be real UTC instants.
  Future<void> add(DateTime startUtc, DateTime endUtc, String reason) async {
    await _db.from('blocked_times').insert({
      'start_time': startUtc.toIso8601String(),
      'end_time': endUtc.toIso8601String(),
      'reason': reason.isEmpty ? null : reason,
    });
  }

  Future<void> delete(String id) async {
    await _db.from('blocked_times').delete().eq('id', id);
  }

  /// Creates weekday lunch blocks for the next [days] days. Returns how many were added.
  Future<int> extendLunchBlocks(int days) async {
    final result = await _db.rpc('seed_lunch_blocks', params: {'p_days': days});
    return (result as num).toInt();
  }
}
