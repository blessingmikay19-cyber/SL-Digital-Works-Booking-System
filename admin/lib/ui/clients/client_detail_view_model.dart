import 'package:flutter/foundation.dart';

import '../../data/models/booking.dart';
import '../../data/models/client.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/client_repository.dart';

class ClientDetailViewModel extends ChangeNotifier {
  ClientDetailViewModel(this._clients, this._bookings, this.clientId) {
    load();
  }

  final ClientRepository _clients;
  final BookingRepository _bookings;
  final String clientId;
  bool _disposed = false;

  Client? client;
  List<Booking> bookings = [];
  bool loading = true;
  bool saving = false;
  String? error;

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _clients.fetchById(clientId),
        _bookings.fetchForClient(clientId),
      ]);
      client = results[0] as Client;
      bookings = results[1] as List<Booking>;
      error = null;
    } catch (_) {
      error = 'Could not load this client.';
    }
    loading = false;
    _notify();
  }

  /// Returns false if saving failed.
  Future<bool> saveNotes(String notes) async {
    saving = true;
    _notify();
    try {
      await _clients.updateNotes(clientId, notes);
      client = await _clients.fetchById(clientId);
      saving = false;
      _notify();
      return true;
    } catch (_) {
      saving = false;
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
