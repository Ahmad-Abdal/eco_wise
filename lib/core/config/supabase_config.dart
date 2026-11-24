import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static const String defaultUrl = '';
  static const String defaultAnonKey =
      '';

  static String get url {
    final fromEnv = dotenv.env['SUPABASE_URL'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    return defaultUrl;
  }

  static String get anonKey {
    final fromEnv = dotenv.env['SUPABASE_ANON_KEY'];
    if (fromEnv != null && fromEnv.trim().isNotEmpty) return fromEnv.trim();
    return defaultAnonKey;
  }
}
