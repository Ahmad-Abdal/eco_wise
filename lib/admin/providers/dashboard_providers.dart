import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardStats {
  final int storeCount;
  final int productCount;
  final int userCount;
  final int scanCount;

  const DashboardStats({
    required this.storeCount,
    required this.productCount,
    required this.userCount,
    required this.scanCount,
  });
}

class StoreOverview {
  final String name;
  final int productCount;

  const StoreOverview({required this.name, required this.productCount});
}

enum ActivityType { productAdded, productUpdated, productScanned, userJoined }

class ActivityItem {
  final ActivityType type;
  final String title;
  final String? subtitle;
  final String timeAgo;

  const ActivityItem({
    required this.type,
    required this.title,
    this.subtitle,
    required this.timeAgo,
  });
}

SupabaseClient get supabase => Supabase.instance.client;

// Counts rows in a table. Returns 0 if the table doesn't exist yet
// (fresh project) instead of throwing, so the dashboard stays usable
// while the schema is still being built out.
Future<int> countRows(String table) async {
  try {
    final response = await supabase.from(table).select().count(CountOption.exact);
    return response.count;
  } catch (_) {
    return 0;
  }
}

// The admin's display name, pulled from Supabase Auth user metadata
// (set via `raw_user_meta_data`), not hardcoded anywhere.
final adminDisplayNameProvider = Provider.autoDispose<String?>((ref) {
  final user = supabase.auth.currentUser;
  final name = user?.userMetadata?['name'] as String?;
  return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
});

// TODO: `scans` table doesn't exist yet — once it does, this will start
// returning a real count automatically.
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final results = await Future.wait([
    countRows('stores'),
    countRows('products'),
    countRows('profiles'),
    countRows('scans'),
  ]);

  return DashboardStats(
    storeCount: results[0],
    productCount: results[1],
    userCount: results[2],
    scanCount: results[3],
  );
});

// Expects a `products` table with a `store_id` foreign key to `stores`
// so PostgREST can embed the per-store product count. Returns an empty
// list (rather than throwing) if `stores` doesn't exist yet.
final storesOverviewProvider = FutureProvider.autoDispose<List<StoreOverview>>((ref) async {
  try {
    final response =
        await supabase.from('stores').select('name, products(count)');

    return (response as List<dynamic>).map((row) {
      final productsField = row['products'];
      var count = 0;
      if (productsField is List && productsField.isNotEmpty) {
        count = (productsField.first['count'] as int?) ?? 0;
      }
      return StoreOverview(
        name: row['name'] as String? ?? 'Unnamed store',
        productCount: count,
      );
    }).toList();
  } catch (_) {
    return [];
  }
});

// TODO: Create an `activity_log` table (e.g. columns: type, title,
// subtitle, created_at) and query it here once store/product actions
// start writing to it. Until then there is nothing to show.
final recentActivityProvider = FutureProvider.autoDispose<List<ActivityItem>>((ref) async {
  return [];
});