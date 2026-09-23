import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScoredProduct {
  final String id;
  final String name;
  final String? brand;
  final String imageUrl;
  final double price;
  final int ecoScore;

  const ScoredProduct({
    required this.id,
    required this.name,
    this.brand,
    required this.imageUrl,
    required this.price,
    required this.ecoScore,
  });
}

SupabaseClient get _supabase => Supabase.instance.client;

// Rule-based recommendation: scores every candidate product against
// the signed-in user's onboarding preferences (categories,
// sustainability priorities, price band) and returns the top matches.
// Falls back to a plain eco-score ranking for a user who skipped
// onboarding (or hasn't rated/scanned anything yet) — same cold-start
// behavior as browsing with no personalization at all.
Future<List<ScoredProduct>> fetchPersonalizedProducts({int limit = 20}) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final profile = await _supabase
        .from('profiles')
        .select('preferred_categories, sustainability_preferences, price_preference')
        .eq('id', userId)
        .maybeSingle();

    final preferredCategories =
        (profile?['preferred_categories'] as List<dynamic>?)?.cast<String>() ?? [];
    final sustainabilityPrefs =
        (profile?['sustainability_preferences'] as List<dynamic>?)?.cast<String>() ?? [];
    final pricePreference = profile?['price_preference'] as String?;

    final hasAnyPreference = preferredCategories.isNotEmpty ||
        sustainabilityPrefs.isNotEmpty ||
        pricePreference != null;

    debugPrint(
      'Personalization read for user $userId — '
      'categories: $preferredCategories, '
      'sustainability: $sustainabilityPrefs, '
      'price: $pricePreference, '
      'hasAnyPreference: $hasAnyPreference',
    );

    final response = await _supabase.from('products').select();
    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();

    if (!hasAnyPreference || rows.isEmpty) {
      // Cold start / skipped onboarding: plain eco-score ranking.
      debugPrint('Using eco-score fallback (no preferences found or no products).');
      rows.sort((a, b) => ((b['eco_score'] as num?) ?? 0).compareTo((a['eco_score'] as num?) ?? 0));
      return rows.take(limit).map(_toScoredProduct).toList();
    }

    final prices = rows.map((row) => ((row['price'] as num?) ?? 0).toDouble()).toList();
    final maxPrice = prices.isEmpty ? 1.0 : prices.reduce((a, b) => a > b ? a : b);

    final scored = rows.map((row) {
      var score = 0.0;

      final category = row['category'] as String?;
      if (category != null && preferredCategories.contains(category)) {
        score += 30;
      }

      final ecoScore = ((row['eco_score'] as num?) ?? 0).toDouble();
      final material = (row['material'] as String? ?? '').toLowerCase();
      final reusable = (row['reusable'] as String? ?? '').toLowerCase();
      final recyclable = (row['recyclable'] as String? ?? '').toLowerCase();
      final packaging = (row['packaging'] as String? ?? '').toLowerCase();
      final price = ((row['price'] as num?) ?? 0).toDouble();

      for (final pref in sustainabilityPrefs) {
        switch (pref) {
          case 'high_eco_score':
            score += (ecoScore / 100) * 20;
            break;
          case 'reusable':
            if (reusable == 'yes') score += 15;
            break;
          case 'recyclable':
            if (recyclable == 'yes') score += 15;
            break;
          case 'natural_organic':
            if (material.contains('organic') ||
                material.contains('natural') ||
                material.contains('bamboo')) {
              score += 15;
            }
            break;
          case 'affordable':
            score += (1 - (price / maxPrice)) * 15;
            break;
          case 'sustainable_packaging':
            if (packaging == 'low') score += 15;
            break;
        }
      }

      if (pricePreference != null) {
        final inBudgetBand = pricePreference == 'Budget' && price < 1000;
        final inModerateBand = pricePreference == 'Moderate' && price >= 1000 && price <= 3000;
        final inPremiumBand = pricePreference == 'Premium' && price > 3000;
        if (inBudgetBand || inModerateBand || inPremiumBand) score += 10;
      }

      return MapEntry(row, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((entry) => _toScoredProduct(entry.key)).toList();
  } catch (error) {
    debugPrint('fetchPersonalizedProducts failed: $error');
    return [];
  }
}

ScoredProduct _toScoredProduct(Map<String, dynamic> row) {
  return ScoredProduct(
    id: row['id'] as String,
    name: row['name'] as String? ?? 'Unnamed product',
    brand: row['brand'] as String?,
    imageUrl: row['image_url'] as String? ?? '',
    price: ((row['price'] as num?) ?? 0).toDouble(),
    ecoScore: ((row['eco_score'] as num?) ?? 0).toInt(),
  );
}