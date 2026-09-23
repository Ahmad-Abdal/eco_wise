import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_providers.dart';
import 'add_store_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  static const activityIconColors = [primaryGreen, Color(0xFF2FA362), Color(0xFF0E8A6E), Color(0xFF3E9B5E)];

  String buildGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  IconData iconForActivity(ActivityType type) {
    switch (type) {
      case ActivityType.productAdded:
        return Icons.inventory_2_outlined;
      case ActivityType.productUpdated:
        return Icons.edit_outlined;
      case ActivityType.productScanned:
        return Icons.qr_code_scanner_rounded;
      case ActivityType.userJoined:
        return Icons.person_add_alt_1_outlined;
    }
  }

  void openAddStoreScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStoreScreen()),
    );
  }

  void showSelectStoreSheet(BuildContext context, List<StoreOverview> stores) {
    if (stores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a store first, then add products to it.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: borderGray, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select store',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                ),
                const SizedBox(height: 12),
                for (final store in stores)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.storefront_rounded, color: primaryGreen, size: 20),
                    ),
                    title: Text(store.name, style: const TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: textGray),
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to the Add product form for
                      // this store.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Add product form for ${store.name} goes here')),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final storesAsync = ref.watch(storesOverviewProvider);
    final activityAsync = ref.watch(recentActivityProvider);
    final adminName = ref.watch(adminDisplayNameProvider);

    return RefreshIndicator(
      color: primaryGreen,
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(storesOverviewProvider);
        ref.invalidate(recentActivityProvider);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero header with a floating live summary card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryGreen, Color(0xFF2FA362)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18)),
                      child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${buildGreeting()}, ${adminName ?? 'Admin'}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            "Here's your EcoWise overview.",
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                statsAsync.when(
                  loading: () => const SizedBox(height: 68),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (stats) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      children: [
                        _heroStatCell(icon: Icons.storefront_rounded, label: 'Stores', value: '${stats.storeCount}'),
                        Container(width: 1, height: 38, color: borderGray),
                        _heroStatCell(icon: Icons.inventory_2_outlined, label: 'Products', value: '${stats.productCount}'),
                        Container(width: 1, height: 38, color: borderGray),
                        _heroStatCell(icon: Icons.people_outline_rounded, label: 'Users', value: '${stats.userCount}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                statsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                  ),
                  error: (error, stack) => const Text('Could not load dashboard stats.', style: TextStyle(color: textDark)),
                  data: (stats) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.65,
                    children: [
                      buildStatCard(icon: Icons.storefront_rounded, label: 'Stores', value: '${stats.storeCount}'),
                      buildStatCard(icon: Icons.inventory_2_outlined, label: 'Products', value: '${stats.productCount}'),
                      buildStatCard(icon: Icons.people_outline_rounded, label: 'Users', value: '${stats.userCount}'),
                      buildStatCard(icon: Icons.qr_code_scanner_rounded, label: 'Scans', value: '${stats.scanCount}'),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text('Quick actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: buildActionButton(
                        icon: Icons.add_business_rounded,
                        label: 'Add store',
                        filled: true,
                        onTap: () => openAddStoreScreen(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: buildActionButton(
                        icon: Icons.add_box_outlined,
                        label: 'Add product',
                        filled: false,
                        onTap: () {
                          final stores = storesAsync.maybeWhen(
                            data: (data) => data,
                            orElse: () => <StoreOverview>[],
                          );
                          showSelectStoreSheet(context, stores);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Text('Recent activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 12),
                activityAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                  ),
                  error: (error, stack) => const Text('Could not load recent activity.', style: TextStyle(color: textDark)),
                  data: (activities) {
                    if (activities.isEmpty) {
                      return buildEmptyState(
                        icon: Icons.history_rounded,
                        message: 'Nothing has happened yet — activity will show up here.',
                      );
                    }
                    return Column(
                      children: [
                        for (final entry in activities.asMap().entries)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: pureWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: borderGray),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: activityIconColors[entry.key % activityIconColors.length].withOpacity(0.12),
                                  ),
                                  child: Icon(
                                    iconForActivity(entry.value.type),
                                    color: activityIconColors[entry.key % activityIconColors.length],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(entry.value.title, style: const TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                                      if (entry.value.subtitle != null)
                                        Text(entry.value.subtitle!, style: const TextStyle(color: textGray, fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Text(entry.value.timeAgo, style: TextStyle(color: textGray.withOpacity(0.7), fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStatCell({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 20),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: textGray, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: lightGreenBg),
            child: Icon(icon, color: primaryGreen.withOpacity(0.7), size: 26),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: textGray.withOpacity(0.85), fontSize: 13)),
        ],
      ),
    );
  }

  Widget buildStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGray),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: primaryGreen, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textDark, height: 1.1)),
          Text(label, style: const TextStyle(fontSize: 11.5, color: textGray, fontWeight: FontWeight.w500, height: 1.1)),
        ],
      ),
    );
  }

  Widget buildActionButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 58,
      child: filled
          ? ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: pureWhite,
                side: const BorderSide(color: borderGray, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(9)),
                    child: Icon(icon, color: primaryGreen, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
    );
  }
}