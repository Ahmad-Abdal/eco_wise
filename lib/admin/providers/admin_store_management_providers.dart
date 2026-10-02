import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient get _supabase => Supabase.instance.client;

class AdminStoreDetail {
  final String id;
  final String name;
  final String imageUrl;
  final String storeType;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String? description;

  const AdminStoreDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.storeType,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.website,
    this.openingHours,
    this.description,
  });

  factory AdminStoreDetail.fromMap(Map<String, dynamic> map) {
    return AdminStoreDetail(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      storeType: map['store_type'] as String? ?? 'physical',
      address: map['address'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      openingHours: map['opening_hours'] as String?,
      description: map['description'] as String?,
    );
  }
}

class AdminProductSummary {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int ecoScore;

  const AdminProductSummary({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.ecoScore,
  });

  factory AdminProductSummary.fromMap(Map<String, dynamic> map) {
    return AdminProductSummary(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unnamed product',
      imageUrl: map['image_url'] as String? ?? '',
      price: ((map['price'] as num?) ?? 0).toDouble(),
      ecoScore: ((map['eco_score'] as num?) ?? 0).toInt(),
    );
  }
}

final adminStoreDetailProvider =
    FutureProvider.autoDispose.family<AdminStoreDetail?, String>((ref, storeId) async {
  try {
    final row = await _supabase.from('stores').select().eq('id', storeId).maybeSingle();
    if (row == null) return null;
    return AdminStoreDetail.fromMap(row);
  } catch (error) {
    debugPrint('adminStoreDetailProvider failed: $error');
    return null;
  }
});

final adminStoreRatingSummaryProvider =
    FutureProvider.autoDispose.family<({double average, int count}), String>((ref, storeId) async {
  try {
    final rows = await _supabase.from('store_ratings').select('rating').eq('store_id', storeId);
    final ratings = (rows as List<dynamic>).map((r) => (r['rating'] as num).toDouble()).toList();
    if (ratings.isEmpty) return (average: 0.0, count: 0);
    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    return (average: double.parse(average.toStringAsFixed(1)), count: ratings.length);
  } catch (error) {
    debugPrint('adminStoreRatingSummaryProvider failed: $error');
    return (average: 0.0, count: 0);
  }
});

final adminStoreProductsProvider =
    FutureProvider.autoDispose.family<List<AdminProductSummary>, String>((ref, storeId) async {
  try {
    final rows = await _supabase.from('products').select().eq('store_id', storeId).order('name');
    return (rows as List<dynamic>)
        .map((row) => AdminProductSummary.fromMap(row as Map<String, dynamic>))
        .toList();
  } catch (error) {
    debugPrint('adminStoreProductsProvider failed: $error');
    return [];
  }
});

/// Deletes every product belonging to a store, then the store itself.
/// Done as two explicit steps rather than relying on an assumed
/// ON DELETE CASCADE on the products.store_id foreign key, since that
/// constraint's exact definition isn't something this code controls.
Future<void> deleteStoreAndProducts(String storeId) async {
  await _supabase.from('products').delete().eq('store_id', storeId);
  await _supabase.from('stores').delete().eq('id', storeId);
}

Future<void> deleteProduct(String productId) async {
  await _supabase.from('products').delete().eq('id', productId);
}