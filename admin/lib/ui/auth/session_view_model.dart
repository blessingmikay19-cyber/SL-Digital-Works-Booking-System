import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

enum SessionStatus { loading, signedOut, notAdmin, admin }

/// Tracks who is signed in and whether they are an admin. The router listens to this.
class SessionViewModel extends ChangeNotifier {
  SessionViewModel(this._auth) {
    _sub = _auth.changes.listen((_) => refresh());
    refresh();
  }

  final AuthRepository _auth;
  late final StreamSubscription<void> _sub;
  SessionStatus status = SessionStatus.loading;

  Future<void> refresh() async {
    if (!_auth.isSignedIn) {
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }
    status = SessionStatus.loading;
    notifyListeners();
    try {
      status = await _auth.isAdmin() ? SessionStatus.admin : SessionStatus.notAdmin;
    } catch (_) {
      status = SessionStatus.notAdmin;
    }
    notifyListeners();
  }

  Future<void> signOut() => _auth.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
