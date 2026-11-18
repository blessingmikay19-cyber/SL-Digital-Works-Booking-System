import 'package:supabase_flutter/supabase_flutter.dart';

/// A sign-in problem with a message that is safe to show to the user.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
}

class AuthRepository {
  final SupabaseClient _db = Supabase.instance.client;

  bool get isSignedIn => _db.auth.currentSession != null;

  /// Fires on sign-in and sign-out (not on routine token refreshes).
  Stream<void> get changes => _db.auth.onAuthStateChange
      .where((s) =>
          s.event != AuthChangeEvent.tokenRefreshed &&
          s.event != AuthChangeEvent.userUpdated)
      .map((_) {});

  Future<void> signIn(String email, String password) async {
    try {
      await _db.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() => _db.auth.signOut();

  Future<bool> isAdmin() async {
    final row = await _db
        .from('admins')
        .select('user_id')
        .eq('user_id', _db.auth.currentUser!.id)
        .maybeSingle();
    return row != null;
  }
}
