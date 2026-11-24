import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin/models/product.dart';
import '../../admin/models/store.dart';

SupabaseClient get _supabase => Supabase.instance.client;

/// Fetches the store owned by the current logged-in vendor.
final currentVendorStoreProvider = FutureProvider.autoDispose<Store?>((ref) async {
  final userId = _supabase.auth.currentUser?.id;
  if (userId == null) return null;

  try {
    final rows = await _supabase
        .from('stores')
        .select()
        .eq('vendor_id', userId)
        .order('created_at', ascending: false)
        .limit(1);

    final list = rows as List<dynamic>;
    if (list.isEmpty) return null;
    return Store.fromMap(list.first as Map<String, dynamic>);
  } catch (e) {
    return null;
  }
});

/// Fetches products belonging exclusively to the current vendor's store.
final vendorStoreProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, storeId) async {
  try {
    final rows = await _supabase
        .from('products')
        .select()
        .eq('store_id', storeId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => Product.fromMap(r as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

/// Metrics for the vendor dashboard.
final vendorMetricsProvider =
    FutureProvider.autoDispose.family<({int productCount, int averageEcoScore}), String>(
        (ref, storeId) async {
  try {
    final rows = await _supabase
        .from('products')
        .select('eco_score')
        .eq('store_id', storeId);

    final list = rows as List<dynamic>;
    if (list.isEmpty) return (productCount: 0, averageEcoScore: 0);

    final scores = list.map((r) => (r['eco_score'] as num?)?.toInt() ?? 0).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;

    return (productCount: list.length, averageEcoScore: avg.round());
  } catch (e) {
    return (productCount: 0, averageEcoScore: 0);
  }
});

class VendorStoreController {
  final Ref ref;
  VendorStoreController(this.ref);

  void _safeInvalidate(dynamic provider) {
    try {
      ref.invalidate(provider);
    } catch (_) {}
  }

  /// Creates a new store for the currently authenticated vendor.
  Future<void> createStore({
    required File imageFile,
    required String name,
    required String storeType,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? website,
    String? openingHours,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated vendor found');

    final ext = imageFile.path.split('.').last;
    final fileName = 'store_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _supabase.storage.from('store-images').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );
    final imageUrl = _supabase.storage.from('store-images').getPublicUrl(fileName);

    final storeData = <String, dynamic>{
      'vendor_id': userId,
      'name': name.trim(),
      'image_url': imageUrl,
      'store_type': storeType,
      'address': address?.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone?.trim(),
      'website': website?.trim(),
      'opening_hours': openingHours?.trim(),
      'description': description?.trim(),
    };

    await _supabase.from('stores').insert(storeData);
    _safeInvalidate(currentVendorStoreProvider);
  }

  Future<void> updateStore({
    required String storeId,
    required String name,
    String? storeType,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? openingHours,
    String? website,
    String? description,
    File? newImageFile,
  }) async {
    String? imageUrl;
    if (newImageFile != null) {
      final ext = newImageFile.path.split('.').last;
      final fileName = 'store_${storeId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _supabase.storage.from('store-images').upload(
            fileName,
            newImageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      imageUrl = _supabase.storage.from('store-images').getPublicUrl(fileName);
    }

    final data = <String, dynamic>{
      'name': name.trim(),
      'phone': phone?.trim(),
      'opening_hours': openingHours?.trim(),
      'website': website?.trim(),
      'description': description?.trim(),
    };
    if (storeType != null) data['store_type'] = storeType;
    if (address != null) data['address'] = address.trim();
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (imageUrl != null) {
      data['image_url'] = imageUrl;
    }

    await _supabase.from('stores').update(data).eq('id', storeId);
    _safeInvalidate(currentVendorStoreProvider);
  }

  /// Submits a store removal request to Admin for review.
  Future<void> requestStoreDeletion(String storeId, String reason) async {
    await _supabase.from('stores').update({
      'deletion_requested': true,
      'deletion_reason': reason.trim(),
      'deletion_requested_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', storeId);
    _safeInvalidate(currentVendorStoreProvider);
  }

  /// Cancels a previously submitted store removal request.
  Future<void> cancelStoreDeletion(String storeId) async {
    await _supabase.from('stores').update({
      'deletion_requested': false,
      'deletion_reason': null,
      'deletion_requested_at': null,
    }).eq('id', storeId);
    _safeInvalidate(currentVendorStoreProvider);
  }

  Future<void> deleteProduct(String productId, String storeId) async {
    await _supabase.from('products').delete().eq('id', productId);
    _safeInvalidate(vendorStoreProductsProvider(storeId));
    _safeInvalidate(vendorMetricsProvider(storeId));
  }
}

final vendorStoreControllerProvider = Provider<VendorStoreController>((ref) {
  return VendorStoreController(ref);
});
