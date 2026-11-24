import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store.dart';
import '../models/product.dart';

final storeListProvider = FutureProvider.autoDispose<List<Store>>((ref) async {
  final supabase = Supabase.instance.client;

  // Query `stores` directly so new/updated fields like deletion_requested,
  // deletion_reason, vendor_id, and is_approved are always live from DB
  // even if the store_summary view doesn't project every column.
  final storeRows = await supabase
      .from('stores')
      .select()
      .order('created_at', ascending: false);

  final Map<String, Map<String, dynamic>> summaryById = {};
  try {
    final summaryRows = await supabase
        .from('store_summary')
        .select('id, average_rating, rating_count, product_count');
    for (final row in (summaryRows as List<dynamic>)) {
      final map = row as Map<String, dynamic>;
      final id = map['id'] as String?;
      if (id != null) summaryById[id] = map;
    }
  } catch (e) {
    debugPrint('store_summary merge skipped: $e');
  }

  final stores = (storeRows as List<dynamic>).map((raw) {
    final map = Map<String, dynamic>.from(raw as Map<String, dynamic>);
    final summary = summaryById[map['id']];
    if (summary != null) {
      map['average_rating'] ??= summary['average_rating'];
      map['rating_count'] ??= summary['rating_count'];
      map['product_count'] ??= summary['product_count'];
    }
    return Store.fromMap(map);
  }).toList();

  // Keep stores with pending deletion requests at the top for admin review.
  stores.sort((a, b) {
    if (a.deletionRequested != b.deletionRequested) {
      return a.deletionRequested ? -1 : 1;
    }
    return 0;
  });

  return stores;
});

final storeProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, storeId) async {
  final supabase = Supabase.instance.client;
  final data = await supabase
      .from('products')
      .select()
      .eq('store_id', storeId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => Product.fromMap(e)).toList();
});