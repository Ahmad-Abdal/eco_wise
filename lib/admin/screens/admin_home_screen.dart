import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_vendor_providers.dart';
import '../providers/analytics_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/store_list_providers.dart';
import '../../user/providers/profile_providers.dart';
import '../../user/widgets/rounded_bottom_nav.dart';
import 'admin_analytics_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_stores_screen.dart';
import 'admin_users_screen.dart';
import 'admin_vendor_requests_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminHomeScreen> createState() => AdminHomeScreenState();
}

class AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  static const Color pureWhite = Colors.white;

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _refreshTabData(0));
  }

  void _refreshTabData(int index) {
    if (!mounted) return;
    switch (index) {
      case 0:
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(storesOverviewProvider);
        ref.invalidate(pendingVendorCountProvider);
        ref.invalidate(storeDeletionRequestsProvider);
        break;
      case 1:
        ref.invalidate(allVendorApplicationsProvider);
        ref.invalidate(storeDeletionRequestsProvider);
        break;
      case 2:
        ref.invalidate(storeListProvider);
        ref.invalidate(storeDeletionRequestsProvider);
        break;
      case 3:
        ref.invalidate(allUsersProvider);
        break;
      case 4:
        ref.invalidate(analyticsSnapshotProvider);
        break;
    }
  }

  void goToTab(int index) {
    setState(() => selectedIndex = index);
    _refreshTabData(index);
  }

  static const tabs = [
    AdminDashboardScreen(),
    AdminVendorRequestsScreen(),
    AdminStoresScreen(),
    AdminUsersScreen(),
    AdminAnalyticsScreen(),
  ];

  static const navItems = [
    NavItemData(icon: Icons.home_rounded, label: 'Dashboard'),
    NavItemData(icon: Icons.assignment_outlined, label: 'Vendors'),
    NavItemData(icon: Icons.storefront_rounded, label: 'Stores'),
    NavItemData(icon: Icons.people_rounded, label: 'Users'),
    NavItemData(icon: Icons.bar_chart_rounded, label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: selectedIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: RoundedBottomNav(
        selectedIndex: selectedIndex,
        onTap: goToTab,
        items: navItems,
      ),
    );
  }
}
