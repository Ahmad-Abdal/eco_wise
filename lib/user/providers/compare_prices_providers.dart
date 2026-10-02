import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scan_providers.dart';

class StoreOffer {
  final ProductDetail product;
  double? distanceKm;

  StoreOffer({required this.product, this.distanceKm});
}

class CompareResult {
  final List<StoreOffer> offers;
  final double originalPrice;

  const CompareResult({required this.offers, required this.originalPrice});

  bool get hasAlternatives => offers.length > 1;

  StoreOffer? get bestPriceOffer {
    if (offers.isEmpty) return null;
    return offers.reduce((a, b) => a.product.price <= b.product.price ? a : b);
  }

  double? get savingsAmount {
    final best = bestPriceOffer;
    if (best == null || best.product.price >= originalPrice) return null;
    return originalPrice - best.product.price;
  }

  double? get savingsPercent {
    final savings = savingsAmount;
    if (savings == null || originalPrice == 0) return null;
    return (savings / originalPrice) * 100;
  }
}

SupabaseClient get _supabase => Supabase.instance.client;

const _productWithStoreSelect =
    '*, stores(id, name, store_type, address, phone, website, latitude, longitude)';

Future<CompareResult> fetchPriceComparison(ProductDetail original) async {
  try {
    final response = await _supabase
        .from('products')
        .select(_productWithStoreSelect)
        .ilike('name', original.name.trim());

    final offers = (response as List<dynamic>)
        .map((row) => ProductDetail.fromMap(row as Map<String, dynamic>))
        // De-duplicate by store — one offer per store, even if a store
        // somehow has more than one matching row.
        .fold<Map<String, ProductDetail>>({}, (map, product) {
          map[product.storeId] = product;
          return map;
        })
        .values
        .map((product) => StoreOffer(product: product))
        .toList();

    await _attachDistances(offers);

    return CompareResult(offers: offers, originalPrice: original.price);
  } catch (error) {
    debugPrint('fetchPriceComparison failed: $error');
    return CompareResult(offers: [StoreOffer(product: original)], originalPrice: original.price);
  }
}

Future<void> _attachDistances(List<StoreOffer> offers) async {
  try {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );

    for (final offer in offers) {
      final store = offer.product.store;
      // Online stores (or any store missing coordinates) simply have
      // no distance to show — not an error, just nothing to compute.
      if (store.latitude == null || store.longitude == null) continue;
      offer.distanceKm = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            store.latitude!,
            store.longitude!,
          ) /
          1000;
    }
  } catch (error) {
    debugPrint('Distance lookup failed (showing prices without distance): $error');
  }
}

Future<bool> _ensureLocationPermission() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
}