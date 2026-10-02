import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin/models/store.dart';

final storeByIdProvider = FutureProvider.autoDispose.family<Store, String>((ref, storeId) async {
  final supabase = Supabase.instance.client;
  final data = await supabase.from('store_summary').select().eq('id', storeId).single();
  return Store.fromMap(data);
});

/// True once the current user has already rated this store — used to
/// decide whether to show the rating prompt when they leave.
final hasUserRatedStoreProvider = FutureProvider.autoDispose.family<bool, String>((ref, storeId) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return true; // no user, nothing to prompt for

  final existing = await supabase
      .from('store_ratings')
      .select('id')
      .eq('store_id', storeId)
      .eq('user_id', userId)
      .maybeSingle();
  return existing != null;
});

class ReviewEntry {
  final int rating;
  final String? comment;
  final String? reviewerName;
  final DateTime createdAt;

  const ReviewEntry({required this.rating, this.comment, this.reviewerName, required this.createdAt});
}

/// Recent reviews with commenter name (joined against profiles).
/// Not explicitly requested but the comment data has nowhere else to
/// surface — small addition on top of the required rating dialog/table.
final recentReviewsProvider = FutureProvider.autoDispose.family<List<ReviewEntry>, String>((ref, storeId) async {
  final supabase = Supabase.instance.client;
  final data = await supabase
      .from('store_reviews_view')
      .select('rating, comment, created_at, reviewer_name')
      .eq('store_id', storeId)
      .order('created_at', ascending: false)
      .limit(20);

  return (data as List).map((row) {
    return ReviewEntry(
      rating: row['rating'] as int,
      comment: row['comment'] as String?,
      reviewerName: row['reviewer_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }).toList();
});

Future<void> submitStoreRating({
  required String storeId,
  required int rating,
  String? comment,
}) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;

  await supabase.from('store_ratings').upsert({
    'store_id': storeId,
    'user_id': userId,
    'rating': rating,
    'comment': (comment == null || comment.trim().isEmpty) ? null : comment.trim(),
  }, onConflict: 'store_id,user_id');
}