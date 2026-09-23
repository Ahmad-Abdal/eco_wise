import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/local_notifications_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? productId;
  final String? storeId;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.productId,
    this.storeId,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        productId: map['product_id'] as String?,
        storeId: map['store_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

const _readIdsPrefsKey = 'read_notification_ids';

final allNotificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final supabase = Supabase.instance.client;
  final data = await supabase.from('notifications').select().order('created_at', ascending: false).limit(50);
  return (data as List).map((e) => AppNotification.fromMap(e)).toList();
});

/// Ids the user has already opened — kept on-device, not in Supabase,
/// since notifications are global (not per-user) and read state is a
/// purely local concern here.
final readNotificationIdsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return (prefs.getStringList(_readIdsPrefsKey) ?? []).toSet();
});

Future<void> markNotificationRead(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final current = (prefs.getStringList(_readIdsPrefsKey) ?? []).toSet();
  current.add(id);
  await prefs.setStringList(_readIdsPrefsKey, current.toList());
}

Future<void> markAllNotificationsRead(List<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  final current = (prefs.getStringList(_readIdsPrefsKey) ?? []).toSet();
  current.addAll(ids);
  await prefs.setStringList(_readIdsPrefsKey, current.toList());
}

/// Live realtime count of unread notifications — drives the badge dot
/// on the bell icon.
final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final all = await ref.watch(allNotificationsProvider.future);
  final readIds = await ref.watch(readNotificationIdsProvider.future);
  return all.where((n) => !readIds.contains(n.id)).length;
});

/// Subscribes to new rows on the notifications table for as long as
/// this is kept alive (call from a StatefulWidget's initState/dispose,
/// e.g. UserHomeShell, so it lives for the whole signed-in session).
/// Fires a local notification banner and refreshes the bell list.
class NotificationsRealtimeListener {
  RealtimeChannel? _channel;

  void start(WidgetRef ref) {
    final supabase = Supabase.instance.client;
    _channel = supabase.channel('public:notifications').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final row = payload.newRecord;
            LocalNotificationsService.show(
              title: row['title'] as String? ?? 'EcoWise',
              body: row['body'] as String? ?? 'New product added.',
              payload: row['product_id'] as String?,
            );
            ref.invalidate(allNotificationsProvider);
            ref.invalidate(unreadCountProvider);
          },
        )..subscribe();
  }

  void stop() {
    _channel?.unsubscribe();
    _channel = null;
  }
}