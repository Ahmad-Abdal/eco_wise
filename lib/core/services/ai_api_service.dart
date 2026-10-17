import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

/// One product the AI server suggests as a greener swap.
class GreenerAlternative {
  final String id;
  final String name;
  final String? brand;
  final String? category;
  final double price;
  final String imageUrl;
  final int ecoScore;
  final double similarity;
  final int ecoGain;

  const GreenerAlternative({
    required this.id,
    required this.name,
    this.brand,
    this.category,
    required this.price,
    required this.imageUrl,
    required this.ecoScore,
    required this.similarity,
    required this.ecoGain,
  });

  /// 0.85 similarity → "85% match".
  int get matchPercent => (similarity * 100).round().clamp(0, 100);

  factory GreenerAlternative.fromMap(Map<String, dynamic> map) {
    return GreenerAlternative(
      id: map['id'].toString(),
      name: map['name'] as String? ?? 'Unnamed product',
      brand: map['brand'] as String?,
      category: map['category'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      imageUrl: map['image_url'] as String? ?? '',
      ecoScore: (map['eco_score'] as num?)?.toInt() ?? 0,
      similarity: (map['similarity'] as num?)?.toDouble() ?? 0,
      ecoGain: (map['eco_gain'] as num?)?.toInt() ?? 0,
    );
  }
}

/// [serverReachable] = false means the AI server is off or failed —
/// the app should hide the feature quietly, never crash.
class AlternativesResult {
  final List<GreenerAlternative> alternatives;
  final bool serverReachable;

  const AlternativesResult({required this.alternatives, required this.serverReachable});

  static const offline = AlternativesResult(alternatives: [], serverReachable: false);
}

/// All calls to the FastAPI + MiniLM server live here.
class AiApiService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    // Skips ngrok's browser warning page (harmless for other hosts).
    'ngrok-skip-browser-warning': 'true',
  };

  static Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${AiConfig.baseUrl}$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  /// Similar products with a higher eco score than [productId].
  static Future<AlternativesResult> fetchGreenerAlternatives(String productId, {int limit = 3}) async {
    if (!AiConfig.isConfigured) {
      debugPrint('AI_SERVER_URL is not set in .env');
      return AlternativesResult.offline;
    }
    try {
      final response = await http
          .get(_uri('/alternatives/$productId', {'limit': '$limit'}), headers: _headers)
          .timeout(AiConfig.timeout);
      if (response.statusCode != 200) {
        debugPrint('Alternatives request failed (${response.statusCode}): ${response.body}');
        return AlternativesResult.offline;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (body['alternatives'] as List<dynamic>? ?? [])
          .map((item) => GreenerAlternative.fromMap(item as Map<String, dynamic>))
          .toList();
      return AlternativesResult(alternatives: list, serverReachable: true);
    } catch (error) {
      debugPrint('AI server unreachable: $error');
      return AlternativesResult.offline;
    }
  }

  /// Creates/refreshes the MiniLM embedding for one product.
  /// Best-effort: returns false if the server is off — the product is
  /// still saved, and Cell 6 (embed-all) can fill it later.
  static Future<bool> embedProduct(String productId) async {
    if (!AiConfig.isConfigured) return false;
    try {
      final response = await http
          .post(_uri('/embed/$productId'), headers: _headers)
          .timeout(AiConfig.timeout);
      if (response.statusCode != 200) {
        debugPrint('Embedding failed (${response.statusCode}): ${response.body}');
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('Embedding skipped, AI server unreachable: $error');
      return false;
    }
  }
}