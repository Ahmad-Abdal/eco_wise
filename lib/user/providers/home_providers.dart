import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'personalized_products_provider.dart';
import 'profile_providers.dart';

/// Personalized recommendations — scores products against the user's
/// onboarding preferences (categories, sustainability priorities,
/// price band). Falls back to a plain eco-score ranking automatically
/// when the user skipped onboarding or set no preferences.
final recommendedProductsProvider = FutureProvider.autoDispose<List<ScoredProduct>>((ref) async {
  return fetchPersonalizedProducts(limit: 20);
});

/// User's own eco score. Returns null until the interaction-tracking
/// engine (user_product_interactions table + scoring) is built —
/// UI shows "Not calculated yet" in that case rather than a fake number.
/// User's Eco-Score = average eco_score of the distinct products they scanned.
/// Returns null until they've scanned at least 3 different products.
final userEcoScoreProvider = FutureProvider.autoDispose<int?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  // 1. Which products has this user scanned?
  final scanRows = await supabase
      .from('scans')
      .select('product_id')
      .eq('user_id', userId);

  final productIds = (scanRows as List)
      .map((row) => row['product_id']?.toString())
      .whereType<String>()
      .toSet() // each product counted once
      .toList();

  if (productIds.length < 3) return null;

  // 2. Get their eco scores and average them.
  final productRows = await supabase
      .from('products')
      .select('eco_score')
      .inFilter('id', productIds);

  final scores = (productRows as List)
      .map((row) => (row['eco_score'] as num?)?.toDouble())
      .whereType<double>()
      .toList();

  if (scores.isEmpty) return null;
  return (scores.reduce((a, b) => a + b) / scores.length).round();
});

final userDisplayNameProvider = Provider.autoDispose<String?>((ref) {
  final profile = ref.watch(currentProfileProvider).value;
  final profileName = profile?.name.trim();
  if (profileName != null && profileName.isNotEmpty) return profileName;

  final metaName = Supabase.instance.client.auth.currentUser?.userMetadata?['name'] as String?;
  return (metaName != null && metaName.trim().isNotEmpty) ? metaName.trim() : null;
});