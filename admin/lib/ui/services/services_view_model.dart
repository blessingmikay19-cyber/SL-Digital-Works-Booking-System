import 'package:flutter/foundation.dart';

import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';

class ServicesViewModel extends ChangeNotifier {
  ServicesViewModel(this._repo) {
    load();
  }

  final ServiceRepository _repo;
  bool _disposed = false;

  List<Service> services = [];
  bool loading = true;
  String? error;

  Future<void> load() async {
    try {
      services = await _repo.fetchAll();
      error = null;
    } catch (_) {
      error = 'Could not load services. Pull down to retry.';
    }
    loading = false;
    _notify();
  }

  /// Show or hide a service on the website. Returns false if it failed.
  Future<bool> setActive(Service s, bool active) async {
    try {
      await _repo.setActive(s.id, active);
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
    super.dispose();
  }
}
