import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Where the EcoWise AI (MiniLM) server lives.
/// Set AI_SERVER_URL in your .env file, e.g.
///   AI_SERVER_URL=https://patchy-boasting-dehydrate.ngrok-free.dev
class AiConfig {
  static String get baseUrl {
    final url = (dotenv.env['AI_SERVER_URL'] ?? '').trim();
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static bool get isConfigured => baseUrl.isNotEmpty;

  /// How long to wait for the server before treating it as offline.
  static const Duration timeout = Duration(seconds: 20);
}