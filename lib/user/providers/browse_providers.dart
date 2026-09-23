import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/categories.dart';

class BrowseCategory {
  final String name;
  final String assetPath;

  const BrowseCategory({required this.name, required this.assetPath});
}

// Maps each shared category name to its image file. Add a new
// category in core/constants/categories.dart first, then add its
// filename here and drop the matching image into assets/categories/.
const _categoryAssetFileNames = {
  'Cleaning': 'cleaning.png',
  'Kitchen Accessories': 'kitchen.png',
  'Home & Living': 'home_living.png',
  'Personal Care': 'personal_care.png',
  'Fashion': 'fashion.webp',
  'Laundry': 'laundry.png',
  'Shopping': 'shopping.png',
  'Storage': 'storage.png',
  'Dining': 'dining.png',
};

// Built from the shared productCategories list (core/constants/categories.dart)
// rather than a second hardcoded list, so the Add Product dropdown and
// the Browse grid can never drift apart.
final browseCategories = productCategories.map((name) {
  final fileName = _categoryAssetFileNames[name] ?? 'default.png';
  return BrowseCategory(name: name, assetPath: 'assets/categories/$fileName');
}).toList();

SupabaseClient get supabase => Supabase.instance.client;

// Only terms that have been searched 4+ times show up — starts empty
// on a fresh project, exactly as intended, and fills in on its own as
// real search activity happens.
final popularSearchesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  try {
    final response = await supabase
        .from('search_terms')
        .select('term')
        .gte('search_count', 4)
        .order('search_count', ascending: false)
        .limit(6);

    return (response as List<dynamic>).map((row) => row['term'] as String).toList();
  } catch (_) {
    return [];
  }
});

// Call this whenever a user submits a search. Best-effort: a logging
// failure should never block the search itself.
Future<void> logSearchTerm(String rawTerm) async {
  final term = rawTerm.trim().toLowerCase();
  if (term.isEmpty) return;
  try {
    await supabase.rpc('increment_search_term', params: {'p_term': term});
  } catch (_) {
    // Ignored.
  }
}