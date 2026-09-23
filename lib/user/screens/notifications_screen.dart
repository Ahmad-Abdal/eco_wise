import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  String formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(allNotificationsProvider);
    final readIdsAsync = ref.watch(readNotificationIdsProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Notifications', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        actions: [
          notificationsAsync.maybeWhen(
            data: (list) => TextButton(
              onPressed: list.isEmpty
                  ? null
                  : () async {
                      await markAllNotificationsRead(list.map((n) => n.id).toList());
                      ref.invalidate(readNotificationIdsProvider);
                      ref.invalidate(unreadCountProvider);
                    },
              child: const Text('Mark all read', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: () async {
          ref.invalidate(allNotificationsProvider);
          ref.invalidate(readNotificationIdsProvider);
        },
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
          error: (e, s) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(child: Text('Could not load notifications.\n$e', textAlign: TextAlign.center, style: const TextStyle(color: textDark))),
            ],
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: sectionFill),
                          child: Icon(Icons.notifications_none_rounded, size: 38, color: textGray.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No notifications yet', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('New product alerts will show up here.', style: TextStyle(color: textGray.withOpacity(0.75))),
                      ],
                    ),
                  ),
                ],
              );
            }

            final readIds = readIdsAsync.asData?.value ?? {};

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isUnread = !readIds.contains(notification.id);

                return GestureDetector(
                  onTap: () async {
                    if (isUnread) {
                      await markNotificationRead(notification.id);
                      ref.invalidate(readNotificationIdsProvider);
                      ref.invalidate(unreadCountProvider);
                    }
                    // TODO: navigate to the product's detail screen using
                    // notification.productId once that route accepts a
                    // fetch-by-id path (currently ProductDetailScreen
                    // expects a full ProductDetail object from scan/browse
                    // flows, not a bare id).
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUnread ? lightGreenBg.withOpacity(0.5) : pureWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isUnread ? primaryGreen.withOpacity(0.25) : borderGray),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: isUnread ? primaryGreen : sectionFill),
                          child: Icon(Icons.eco_rounded, color: isUnread ? Colors.white : textGray, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(notification.title,
                                        style: TextStyle(color: textDark, fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
                                  ),
                                  if (isUnread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(left: 6, top: 4),
                                      decoration: const BoxDecoration(shape: BoxShape.circle, color: primaryGreen),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(notification.body, style: TextStyle(color: textGray.withOpacity(0.9), fontSize: 12.5, height: 1.35)),
                              const SizedBox(height: 6),
                              Text(formatRelativeTime(notification.createdAt), style: TextStyle(color: textGray.withOpacity(0.6), fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}