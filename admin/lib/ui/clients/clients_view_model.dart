import 'package:flutter/foundation.dart';

import '../../data/models/client.dart';
import '../../data/repositories/client_repository.dart';

class ClientsViewModel extends ChangeNotifier {
  ClientsViewModel(this._repo) {
    load();
  }

  final ClientRepository _repo;
  bool _disposed = false;
  List<Client> _all = [];
  String _query = '';

  bool loading = true;
  String? error;

  bool get hasAny => _all.isNotEmpty;

  /// Clients matching the search box (name, email or phone).
  List<Client> get clients {
    if (_query.isEmpty) return _all;
    final q = _query.toLowerCase();
    return _all
        .where((c) =>
            c.fullName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.phone.contains(q))
        .toList();
  }

  void search(String query) {
    _query = query.trim();
    _notify();
  }

  Future<void> load() async {
    try {
      final list = await _repo.fetchAll();
      list.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
      _all = list;
      error = null;
    } catch (_) {
      error = 'Could not load clients. Pull down to retry.';
    }
    loading = false;
    _notify();
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
