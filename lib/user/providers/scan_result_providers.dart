import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecentScan {
  final String productId;
  final String name;
  final String? brand;
  final String imageUrl;
  final double price;
  final int ecoScore;
  final DateTime? scannedAt;

  const RecentScan({
    required this.productId,
    required this.name,
    this.brand,
    required this.imageUrl,
    required this.price,
    required this.ecoScore,
    this.scannedAt,
  });
}

/// The signed-in user's last 3 different scanned products (newest first).
final recentScansProvider = FutureProvider.autoDispose<List<RecentScan>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  try {
    final rows = await supabase
        .from('scans')
        .select('product_id, scanned_at, products(id, name, brand, price, image_url, eco_score)')
        .eq('user_id', userId)
        .order('scanned_at', ascending: false)
        .limit(30);

    final seen = <String>{};
    final recent = <RecentScan>[];
    for (final row in rows as List<dynamic>) {
      final product = row['products'] as Map<String, dynamic>?;
      if (product == null) continue; // product was deleted
      final id = product['id'].toString();
      if (!seen.add(id)) continue; // each product once
      recent.add(RecentScan(
        productId: id,
        name: product['name'] as String? ?? 'Unnamed product',
        brand: product['brand'] as String?,
        imageUrl: product['image_url'] as String? ?? '',
        price: (product['price'] as num?)?.toDouble() ?? 0,
        ecoScore: (product['eco_score'] as num?)?.toInt() ?? 0,
        scannedAt: DateTime.tryParse(row['scanned_at']?.toString() ?? ''),
      ));
      if (recent.length == 3) break;
    }
    return recent;
  } catch (error) {
    debugPrint('recentScansProvider failed: $error');
    return [];
  }
});