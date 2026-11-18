import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client.dart';

class ClientRepository {
  final SupabaseClient _db = Supabase.instance.client;

  static const _columns = 'id,full_name,email,phone,notes,created_at,bookings(count)';

  Future<List<Client>> fetchAll() async {
    final data = await _db.from('clients').select(_columns);
    return (data as List)
        .map((m) => Client.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  Future<Client> fetchById(String id) async {
    final m = await _db.from('clients').select(_columns).eq('id', id).single();
    return Client.fromMap(Map<String, dynamic>.from(m));
  }

  Future<void> updateNotes(String id, String notes) async {
    final value = notes.trim();
    await _db.from('clients').update({'notes': value.isEmpty ? null : value}).eq('id', id);
  }
}
