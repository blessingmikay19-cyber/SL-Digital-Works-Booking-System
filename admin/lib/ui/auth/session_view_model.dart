
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

enum SessionStatus { loading, signedOut, notAdmin, admin }

class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._auth) {
    _sub = _auth.changes.listen((_) => refresh());
    refresh();
  }

  final AuthRepository _auth;
  late final StreamSubscription<void> _sub;

  SessionStatus status = SessionStatus.loading;

  int _refreshGeneration = 0;

  Future<void> refresh() async {
    final generation = ++_refreshGeneration;

    if (!_auth.isSignedIn) {
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }

    status = SessionStatus.loading;
    notifyListeners();

    try {
      final isAdmin = await _auth.isAdmin();

      if (generation != _refreshGeneration) return;

      status = isAdmin
          ? SessionStatus.admin
          : SessionStatus.notAdmin;
    } catch (_) {
      if (generation != _refreshGeneration) return;

      status = SessionStatus.notAdmin;
    }

    if (!hasListeners || generation != _refreshGeneration) return;

    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _refreshGeneration++;
    _sub.cancel();
    super.dispose();
  }
}
