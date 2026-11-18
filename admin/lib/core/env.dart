import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to values from the .env file.
class Env {
  Env._();

  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseKey => _get('SUPABASE_PUBLISHABLE_KEY');

  static String _get(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('Missing $key in assets/env');
    }
    return value;
  }
}
