import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._auth);

  final AuthRepository _auth;
  bool busy = false;
  String? error;
  bool _disposed = false;

  Future<void> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      error = 'Enter your email and password.';
      _notify();
      return;
    }
    busy = true;
    error = null;
    _notify();
    try {
      await _auth.signIn(email.trim(), password);
    } on AuthFailure catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
    }
    busy = false;
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
