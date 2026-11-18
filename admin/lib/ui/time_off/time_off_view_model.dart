import 'package:flutter/foundation.dart';

import '../../data/models/blocked_time.dart';
import '../../data/repositories/blocked_time_repository.dart';

class TimeOffViewModel extends ChangeNotifier {
  TimeOffViewModel(this._repo) {
    load();
  }

  final BlockedTimeRepository _repo;
  bool _disposed = false;
  List<BlockedTime> _all = [];

  bool loading = true;
  bool busy = false;
  bool showLunch = false;
  String? error;

  int get lunchCount => _all.where((b) => b.isLunch).length;
  List<BlockedTime> get visible => showLunch ? _all : _all.where((b) => !b.isLunch).toList();

  void setShowLunch(bool value) {
    showLunch = value;
    _notify();
  }

  Future<void> load() async {
    try {
      _all = await _repo.fetchUpcoming();
      error = null;
    } catch (_) {
      error = 'Could not load time off. Pull down to retry.';
    }
    loading = false;
    _notify();
  }

  Future<bool> remove(BlockedTime b) async {
    try {
      await _repo.delete(b.id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the number of lunch blocks added, or null if it failed.
  Future<int?> extendLunch() async {
    busy = true;
    _notify();
    try {
      final added = await _repo.extendLunchBlocks(90);
      await load();
      busy = false;
      _notify();
      return added;
    } catch (_) {
      busy = false;
      _notify();
      return null;
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
