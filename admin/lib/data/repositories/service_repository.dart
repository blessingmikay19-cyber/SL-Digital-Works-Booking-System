import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service.dart';

class ServiceRepository {
  final SupabaseClient _db = Supabase.instance.client;

  static const _columns = 'id,name,description,duration_minutes,price,active';

  /// All services, including inactive ones (admins can see everything).
  Future<List<Service>> fetchAll() async {
    final data =
        await _db.from('services').select(_columns).order('duration_minutes').order('name');
    return (data as List)
        .map((m) => Service.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<Service> fetchById(String id) async {
    final m = await _db.from('services').select(_columns).eq('id', id).single();
    return Service.fromMap(Map<String, dynamic>.from(m));
  }

  /// Creates a service, or updates it when [id] is given.
  Future<void> save({
    String? id,
    required String name,
    required String description,
    required int durationMinutes,
    required num price,
    required bool active,
  }) async {
    final row = {
      'name': name,
      'description': description.isEmpty ? null : description,
      'duration_minutes': durationMinutes,
      'price': price,
      'active': active,
    };
    if (id == null) {
      await _db.from('services').insert(row);
    } else {
      await _db.from('services').update(row).eq('id', id);
    }
  }

  Future<void> setActive(String id, bool active) async {
    await _db.from('services').update({'active': active}).eq('id', id);
  }
}
