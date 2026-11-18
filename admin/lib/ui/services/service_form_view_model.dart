import 'package:flutter/foundation.dart';

import '../../data/models/service.dart';
import '../../data/repositories/service_repository.dart';

/// Add a new service (id is null) or edit an existing one.
class ServiceFormViewModel extends ChangeNotifier {
  ServiceFormViewModel(this._repo, this.id) {
    if (id == null) {
      loading = false;
    } else {
      _load();
    }
  }

  final ServiceRepository _repo;
  final String? id;
  bool _disposed = false;

  bool get isNew => id == null;
  Service? service;
  bool loading = true;
  bool saving = false;
  String? loadError;
  String? saveError;
  Map<String, String> errors = {};

  Future<void> _load() async {
    try {
      service = await _repo.fetchById(id!);
    } catch (_) {
      loadError = 'Could not load this service.';
    }
    loading = false;
    _notify();
  }

  /// Returns true when saved.
  Future<bool> save({
    required String name,
    required String description,
    required String duration,
    required String price,
    required bool active,
  }) async {
    errors = {};
    saveError = null;
    final n = name.trim();
    final d = int.tryParse(duration.trim());
    final p = num.tryParse(price.trim().replaceAll(',', '.'));
    if (n.length < 2) errors['name'] = 'Enter a name.';
    if (d == null || d <= 0 || d > 480) errors['duration'] = 'Enter minutes between 1 and 480.';
    if (p == null || p < 0) errors['price'] = 'Enter a price, or 0 for free.';
    if (errors.isNotEmpty) {
      _notify();
      return false;
    }
    saving = true;
    _notify();
    try {
      await _repo.save(
        id: id,
        name: n,
        description: description.trim(),
        durationMinutes: d!,
        price: p!,
        active: active,
      );
      saving = false;
      _notify();
      return true;
    } catch (_) {
      saving = false;
      saveError = 'Could not save the service. Please try again.';
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
