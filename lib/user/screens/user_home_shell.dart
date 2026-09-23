import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/rounded_bottom_nav.dart';
import '../widgets/chat_fab.dart';
import '../providers/notifications_providers.dart';
import 'home_screen.dart';
import 'stores_screen.dart';
import 'scan_screen.dart';
import 'browse_screen.dart';
import 'wishlist_screen.dart';

class UserHomeShell extends ConsumerStatefulWidget {
  const UserHomeShell({Key? key}) : super(key: key);

  @override
  ConsumerState<UserHomeShell> createState() => UserHomeShellState();
}

class UserHomeShellState extends ConsumerState<UserHomeShell> {
  static const Color appBackground = Color(0xFFFFFFFF);

  int selectedIndex = 0;
  final _notificationsListener = NotificationsRealtimeListener();

  static const tabs = [
    UserHomeScreen(),
    StoresScreen(),
    ScanScreen(),
    BrowseScreen(),
    WishlistScreen(),
  ];

  static const navItems = [
    NavItemData(icon: Icons.home_rounded, label: 'Home'),
    NavItemData(icon: Icons.storefront_rounded, label: 'Stores'),
    NavItemData(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    NavItemData(icon: Icons.search_rounded, label: 'Search'),
    NavItemData(icon: Icons.favorite_border_rounded, label: 'Wishlist'),
  ];

  @override
  void initState() {
    super.initState();
    // Lives for the whole signed-in session — new-product notifications
    // fire (and the bell list refreshes) no matter which tab is open.
    _notificationsListener.start(ref);
  }

  @override
  void dispose() {
    _notificationsListener.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(index: selectedIndex, children: tabs),
            const ChatFab(),
          ],
        ),
      ),
      bottomNavigationBar: RoundedBottomNav(
        selectedIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        items: navItems,
      ),
    );
  }
}