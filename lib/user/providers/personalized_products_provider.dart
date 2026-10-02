import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScoredProduct {
  final String id;
  final String name;
  final String? brand;
  final String imageUrl;
  final double price;
  final int ecoScore;

  /// Why this product was recommended, e.g. ['Personal Care', 'Moderate'].
  final List<String> reasons;

  const ScoredProduct({
    required this.id,
    required this.name,
    this.brand,
    required this.imageUrl,
    required this.price,
    required this.ecoScore,
    this.reasons = const [],
  });
}

SupabaseClient get _supabase => Supabase.instance.client;

double _eco(Map<String, dynamic> row) => ((row['eco_score'] as num?) ?? 0).toDouble();
double _price(Map<String, dynamic> row) => ((row['price'] as num?) ?? 0).toDouble();

bool _inPriceBand(double price, String band) {
  switch (band) {
    case 'Budget':
      return price < 1000;
    case 'Moderate':
      return price >= 1000 && price <= 3000;
    case 'Premium':
      return price > 3000;
    default:
      return true;
  }
}

/// Onboarding choices FILTER the products; eco score ORDERS them.
///
///  1. Category + price match          → shown first
///  2. Category match, other price     → only used to fill up if (1) is short
///  3. Everything else                 → never shown (unless user skipped onboarding)
///
/// Within each group, highest eco score comes first.
Future<List<ScoredProduct>> fetchPersonalizedProducts({int limit = 20}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final profile = await _supabase
        .from('profiles')
        .select('preferred_categories, price_preference')
        .eq('id', userId)
        .maybeSingle();

    final categories =
        (profile?['preferred_categories'] as List<dynamic>?)?.cast<String>() ?? const <String>[];
    final priceBand = profile?['price_preference'] as String?;

    final rows = ((await _supabase.from('products').select()) as List<dynamic>)
        .cast<Map<String, dynamic>>();

    // Always rank by eco score — this is the app's core promise.
    rows.sort((a, b) => _eco(b).compareTo(_eco(a)));

    // Skipped onboarding: just the most eco-friendly products overall.
    if (categories.isEmpty && priceBand == null) {
      return rows.take(limit).map((r) => _toScoredProduct(r, const [])).toList();
    }

    final exactMatches = <ScoredProduct>[];
    final categoryOnly = <ScoredProduct>[];

    for (final row in rows) {
      final category = row['category'] as String?;
      final categoryOk = categories.isEmpty || (category != null && categories.contains(category));
      if (!categoryOk) continue; // outside chosen categories → never recommended

      final priceOk = priceBand == null || _inPriceBand(_price(row), priceBand);
      final reasons = [
        if (categories.isNotEmpty && category != null) category,
        if (priceBand != null && priceOk) priceBand,
      ];

      (priceOk ? exactMatches : categoryOnly).add(_toScoredProduct(row, reasons));
    }

    debugPrint(
      'Personalization for $userId — categories: $categories, price: $priceBand, '
      'exact: ${exactMatches.length}, categoryOnly: ${categoryOnly.length}',
    );

    // Exact matches first; top up with same-category products if the list is short.
    return [...exactMatches, ...categoryOnly].take(limit).toList();
  } catch (error) {
    debugPrint('fetchPersonalizedProducts failed: $error');
    return [];
  }
}

ScoredProduct _toScoredProduct(Map<String, dynamic> row, List<String> reasons) {
  return ScoredProduct(
    id: row['id'] as String,
    name: row['name'] as String? ?? 'Unnamed product',
    brand: row['brand'] as String?,
    imageUrl: row['image_url'] as String? ?? '',
    price: _price(row),
    ecoScore: _eco(row).toInt(),
    reasons: reasons,
  );
}