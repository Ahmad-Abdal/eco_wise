import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'personalized_products_provider.dart';

/// Personalized recommendations — scores products against the user's
/// onboarding preferences (categories, sustainability priorities,
/// price band). Falls back to a plain eco-score ranking automatically
/// when the user skipped onboarding or set no preferences.
final recommendedProductsProvider = FutureProvider.autoDispose<List<ScoredProduct>>((ref) async {
  return fetchPersonalizedProducts(limit: 6);
});

/// User's own eco score. Returns null until the interaction-tracking
/// engine (user_product_interactions table + scoring) is built —
/// UI shows "Not calculated yet" in that case rather than a fake number.
final userEcoScoreProvider = FutureProvider.autoDispose<int?>((ref) async {
  // TODO: replace with real query once user_product_interactions +
  // scoring view exist.
  return null;
});

final userDisplayNameProvider = Provider<String?>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  final name = user?.userMetadata?['name'] as String?;
  return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
});