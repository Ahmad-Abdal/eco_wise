import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreSummary {
  final String id;
  final String name;
  final String storeType;
  final String? address;
  final String? phone;
  final String? website;
  final double? latitude;
  final double? longitude;

  const StoreSummary({
    required this.id,
    required this.name,
    required this.storeType,
    this.address,
    this.phone,
    this.website,
    this.latitude,
    this.longitude,
  });

  factory StoreSummary.fromMap(Map<String, dynamic> map) {
    return StoreSummary(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown store',
      storeType: map['store_type'] as String? ?? 'physical',
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      website: map['website'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}

class ProductDetail {
  final String id;
  final String storeId;
  final String name;
  final String imageUrl;
  final double price;
  final String? brand;
  final String? category;
  final String? description;
  final String material;
  final String recyclable;
  final String reusable;
  final String certification;
  final String packaging;
  final int ecoScore;
  final StoreSummary store;

  const ProductDetail({
    required this.id,
    required this.storeId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.brand,
    this.category,
    this.description,
    required this.material,
    required this.recyclable,
    required this.reusable,
    required this.certification,
    required this.packaging,
    required this.ecoScore,
    required this.store,
  });

  factory ProductDetail.fromMap(Map<String, dynamic> map) {
    return ProductDetail(
      id: map['id'] as String,
      storeId: map['store_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed product',
      imageUrl: map['image_url'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      brand: map['brand'] as String?,
      category: map['category'] as String?,
      description: map['description'] as String?,
      material: map['material'] as String? ?? 'Unknown',
      recyclable: map['recyclable'] as String? ?? 'Unknown',
      reusable: map['reusable'] as String? ?? 'Unknown',
      certification: map['certification'] as String? ?? 'Unknown',
      packaging: map['packaging'] as String? ?? 'Unknown',
      ecoScore: (map['eco_score'] as num?)?.toInt() ?? 0,
      store: StoreSummary.fromMap(
        map['stores'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

SupabaseClient get _supabase => Supabase.instance.client;

const _productWithStoreSelect =
    '*, stores(id, name, store_type, address, phone, website, latitude, longitude)';

// Shared by the Scan screen, Search results (tapping a product card),
// and the Wishlist screen — one place that knows how to turn a
// product id into a full ProductDetail.
Future<ProductDetail?> fetchProductById(String productId) async {
  final id = productId.trim();
  if (id.isEmpty) return null;
  try {
    final response = await _supabase
        .from('products')
        .select(_productWithStoreSelect)
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return ProductDetail.fromMap(response);
  } catch (error) {
    debugPrint('fetchProductById failed: $error');
    return null;
  }
}

class ProductLookupState {
  final bool isLoading;
  final String? errorMessage;
  final ProductDetail? product;

  const ProductLookupState({
    this.isLoading = false,
    this.errorMessage,
    this.product,
  });

  ProductLookupState copyWith({
    bool? isLoading,
    String? errorMessage,
    ProductDetail? product,
  }) {
    return ProductLookupState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      product: product,
    );
  }
}

class ProductLookupNotifier extends Notifier<ProductLookupState> {
  @override
  ProductLookupState build() => const ProductLookupState();

  SupabaseClient get supabase => _supabase;

  Future<void> lookupProduct(String rawCode) async {
    final productId = rawCode.trim();
    if (productId.isEmpty) return;

    state = state.copyWith(isLoading: true, errorMessage: null, product: null);

    final product = await fetchProductById(productId);

    if (product == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No product found for this code.',
      );
      return;
    }

    // Log the scan so it counts toward the admin dashboard's Scans
    // stat. Best-effort: a logging failure shouldn't block showing
    // the product the user actually scanned.
    try {
      await supabase.from('scans').insert({'product_id': productId});
    } catch (error) {
      debugPrint('Scan logging failed: $error');
    }

    state = state.copyWith(isLoading: false, product: product);
  }

  void reset() {
    state = const ProductLookupState();
  }
}

final productLookupNotifierProvider =
    NotifierProvider<ProductLookupNotifier, ProductLookupState>(
  ProductLookupNotifier.new,
);