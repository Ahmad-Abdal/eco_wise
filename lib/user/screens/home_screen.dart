import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/home_providers.dart';
import '../providers/profile_providers.dart';
import '../providers/notifications_providers.dart';
import '../providers/scan_providers.dart';
import 'sign_in_screen.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';

class UserHomeScreen extends ConsumerWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  static const categories = [
    'Sustainable Fashion',
    'Organic Food',
    'Recycled Materials',
    'Zero Waste',
  ];

   void openProfileDialog(BuildContext context, WidgetRef ref, UserProfile? profile) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: pureWhite,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------- Green header with overlapping avatar ----------
                SizedBox(
                  height: 140,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        height: 92,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryGreen, Color(0xFF2FA362)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                        ),
                      ),
                      Positioned(
                        top: 48,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: pureWhite,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: lightGreenBg,
                            backgroundImage: (profile?.avatarUrl != null)
                                ? NetworkImage(profile!.avatarUrl!)
                                : null,
                            child: profile?.avatarUrl == null
                                ? const Icon(Icons.person, color: primaryGreen, size: 36)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- Name, email, city ----------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      Text(
                        profile?.name ?? 'EcoWise user',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      if (profile?.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile!.email!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: textGray, fontSize: 13),
                        ),
                      ],
                      if (profile?.city != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: lightGreenBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, color: primaryGreen, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                profile!.city!,
                                style: const TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ---------- Bio ----------
                      if (profile?.bio != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: sectionFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderGray),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(color: textGray, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile!.bio!,
                                style: const TextStyle(color: textDark, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Divider(color: borderGray, height: 1),
                      const SizedBox(height: 16),

                      // ---------- Log out (same logic as before) ----------
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.08),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();

                            // Clear everything cached for the previous user.
                            ref.invalidate(userDisplayNameProvider);
                            ref.invalidate(currentProfileProvider);
                            ref.invalidate(userEcoScoreProvider);
                            ref.invalidate(recommendedProductsProvider);
                            ref.invalidate(unreadCountProvider);

                            if (!context.mounted) return;
                            Navigator.of(context).pop(); // close dialog
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const SignInScreen()),
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 19),
                          label: const Text(
                            'Log out',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ecoScoreAsync = ref.watch(userEcoScoreProvider);
    final productsAsync = ref.watch(recommendedProductsProvider);
    final displayName = ref.watch(userDisplayNameProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Text('EcoWise', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const Spacer(),
                  Consumer(builder: (context, ref, _) {
                    final unreadAsync = ref.watch(unreadCountProvider);
                    final unreadCount = unreadAsync.asData?.value ?? 0;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                                alignment: Alignment.center,
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => openProfileDialog(context, ref, profileAsync.value),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: (profileAsync.value?.avatarUrl != null)
                          ? NetworkImage(profileAsync.value!.avatarUrl!)
                          : null,
                      child: profileAsync.value?.avatarUrl == null
                          ? const Icon(Icons.person, color: primaryGreen, size: 24)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Hello, ${displayName ?? 'there'}!',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                'Every choice adds up — let\'s keep it green.',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ecoScoreAsync.when(
                loading: () => const SizedBox(height: 64),
                error: (e, s) => const SizedBox.shrink(),
                data: (score) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: score != null ? score / 100 : 0,
                              strokeWidth: 5,
                              backgroundColor: lightGreenBg,
                              valueColor: const AlwaysStoppedAnimation(primaryGreen),
                            ),
                            Icon(Icons.eco_rounded, color: primaryGreen, size: 20),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              score != null ? 'Your Eco-Score' : 'Eco-Score',
                              style: const TextStyle(color: textGray, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              score != null ? '$score/100' : 'Not calculated yet',
                              style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) => Chip(
              label: Text(categories[index], style: const TextStyle(color: textGray, fontSize: 13, fontWeight: FontWeight.w600)),
              backgroundColor: sectionFill,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, color: primaryGreen, size: 22),
            SizedBox(width: 8),
            Text('Top Recommendations for You', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 19)),
          ],
        ),
        const SizedBox(height: 16),
        productsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: primaryGreen)),
          ),
          error: (e, s) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Could not load recommendations.', style: TextStyle(color: textDark)),
          ),
          data: (products) {
            if (products.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No products yet.', style: TextStyle(color: textGray.withOpacity(0.7), fontSize: 15)),
                ),
              );
            }
            return Column(
              children: products.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderGray),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          p.imageUrl,
                          width: 62,
                          height: 62,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 62,
                            height: 62,
                            color: sectionFill,
                            child: const Icon(Icons.inventory_2_outlined, color: textGray, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('\Rs${p.price.toStringAsFixed(2)}',
                                    style: const TextStyle(color: textGray, fontWeight: FontWeight.w700, fontSize: 13)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
                                    child: Text('${p.ecoScore}/100 Eco',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () async {
                          final productId = p.id;
                          if (productId == null) return;
                          final detail = await fetchProductById(productId);
                          if (!context.mounted) return;
                          if (detail == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not load this product.')),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ProductDetailScreen(product: detail)),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
            ],
          ),
        ),
      ],
    );
  }
}