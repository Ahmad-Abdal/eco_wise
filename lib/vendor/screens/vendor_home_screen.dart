import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../user/screens/sign_in_screen.dart';
import '../providers/vendor_dashboard_providers.dart';
import 'vendor_add_product_screen.dart';
import 'vendor_add_store_screen.dart';
import 'vendor_edit_store_screen.dart';
import 'vendor_products_screen.dart';

class VendorHomeScreen extends ConsumerStatefulWidget {
  const VendorHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VendorHomeScreen> createState() => VendorHomeScreenState();
}

class VendorHomeScreenState extends ConsumerState<VendorHomeScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  Future<void> handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your vendor account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  Future<void> handleCancelDeletionRequest(String storeId) async {
    try {
      await ref.read(vendorStoreControllerProvider).cancelStoreDeletion(storeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store removal request cancelled.'),
          backgroundColor: primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel request: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> showRequestDeletionDialog(String storeId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 8),
            Text('Request Store Removal', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Per platform guidelines, removing your store requires Admin Approval. When approved, your store and listed products will be permanently removed.',
              style: TextStyle(color: textGray, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: textDark, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Reason for removal *',
                labelStyle: const TextStyle(color: textGray),
                hintText: 'e.g. Business closing, re-evaluating inventory...',
                filled: true,
                fillColor: sectionFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGray)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderGray)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  const SnackBar(content: Text('Please enter a reason')),
                );
                return;
              }
              Navigator.pop(dialogCtx, true);
            },
            child: const Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(vendorStoreControllerProvider).requestStoreDeletion(
              storeId,
              reasonController.text.trim(),
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store removal request submitted to Admin for review.'),
            backgroundColor: primaryGreen,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit removal request: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget buildStatCard({required String title, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: sectionFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGray),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primaryGreen, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 12, color: textGray, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(currentVendorStoreProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        title: const Text('Vendor Portal', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        actions: [
          storeAsync.maybeWhen(
            data: (store) => store == null
                ? TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: primaryGreen),
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text('Add Store', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VendorAddStoreScreen()),
                      );
                    },
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textDark),
            tooltip: 'Refresh from database',
            onPressed: () {
              final store = ref
                  .read(currentVendorStoreProvider)
                  .maybeWhen(data: (s) => s, orElse: () => null);
              ref.invalidate(currentVendorStoreProvider);
              if (store != null) {
                ref.invalidate(vendorStoreProductsProvider(store.id));
                ref.invalidate(vendorMetricsProvider(store.id));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: textDark),
            tooltip: 'Sign Out',
            onPressed: handleSignOut,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: () async {
            final store = ref
                .read(currentVendorStoreProvider)
                .maybeWhen(data: (s) => s, orElse: () => null);
            ref.invalidate(currentVendorStoreProvider);
            if (store != null) {
              ref.invalidate(vendorStoreProductsProvider(store.id));
              ref.invalidate(vendorMetricsProvider(store.id));
            }
          },
          child: storeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
            error: (e, _) => Center(child: Text('Could not load store data: $e')),
            data: (store) {
              if (store == null) {
                // Empty state when vendor does not have a store yet
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: lightGreenBg,
                        ),
                        child: const Icon(Icons.storefront_rounded, size: 52, color: primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to Vendor Portal!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your vendor account is approved. Set up your store with location, opening hours, and details to begin adding eco-friendly products to the EcoWise marketplace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textGray, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
                        label: const Text(
                          'Create Your Store',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VendorAddStoreScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              final metricsAsync = ref.watch(vendorMetricsProvider(store.id));

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deletion requested banner if active
                    if (store.deletionRequested) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3CD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFEEBA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Store Removal Under Review',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF856404), fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You requested Admin to remove this store.\nReason: "${store.deletionReason ?? 'No reason specified'}"',
                              style: const TextStyle(color: Color(0xFF856404), fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF856404),
                                side: const BorderSide(color: Color(0xFF856404)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => handleCancelDeletionRequest(store.id),
                              child: const Text('Cancel Removal Request', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Store Card Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: pureWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderGray),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: store.imageUrl.isNotEmpty
                                    ? Image.network(
                                        store.imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 60,
                                          height: 60,
                                          color: sectionFill,
                                          child: const Icon(Icons.storefront, color: primaryGreen),
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: sectionFill,
                                        child: const Icon(Icons.storefront, color: primaryGreen),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store.name,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(8)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_rounded, color: primaryGreen, size: 12),
                                          SizedBox(width: 4),
                                          Text('Approved Vendor', style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: primaryGreen),
                                tooltip: 'Edit Store',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => VendorEditStoreScreen(store: store)),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (store.address != null && store.address!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: textGray),
                                const SizedBox(width: 6),
                                Expanded(child: Text(store.address!, style: const TextStyle(fontSize: 12, color: textGray, height: 1.3))),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Metrics row
                    metricsAsync.when(
                      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: primaryGreen))),
                      error: (_, __) => const SizedBox(),
                      data: (metrics) => Row(
                        children: [
                          buildStatCard(
                            title: 'Active Products',
                            value: '${metrics.productCount}',
                            icon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(width: 12),
                          buildStatCard(
                            title: 'Avg. Eco Score',
                            value: metrics.averageEcoScore > 0 ? '${metrics.averageEcoScore}' : 'N/A',
                            icon: Icons.eco_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text('Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white, size: 20),
                            label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VendorAddProductScreen(storeId: store.id, storeName: store.name),
                                ),
                              ).then((_) {
                                ref.invalidate(vendorStoreProductsProvider(store.id));
                                ref.invalidate(vendorMetricsProvider(store.id));
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textDark,
                              side: const BorderSide(color: borderGray, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.format_list_bulleted, color: primaryGreen, size: 20),
                            label: const Text('Manage Items', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VendorProductsScreen(store: store),
                                ),
                              ).then((_) {
                                ref.invalidate(vendorStoreProductsProvider(store.id));
                                ref.invalidate(vendorMetricsProvider(store.id));
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Store Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Store Products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => VendorProductsScreen(store: store)),
                            ).then((_) {
                              ref.invalidate(vendorStoreProductsProvider(store.id));
                              ref.invalidate(vendorMetricsProvider(store.id));
                            });
                          },
                          child: const Text('View All', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Product preview stream
                    Consumer(
                      builder: (context, ref, child) {
                        final productsAsync = ref.watch(vendorStoreProductsProvider(store.id));
                        return productsAsync.when(
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryGreen))),
                          error: (e, _) => Text('Could not load products: $e'),
                          data: (products) {
                            if (products.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                                decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(16)),
                                child: const Center(
                                  child: Text('No products added yet. Tap "Add Product" to create one.', style: TextStyle(color: textGray, fontSize: 13)),
                                ),
                              );
                            }

                            final previewList = products.take(4).toList();
                            return Column(
                              children: previewList.map((p) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: sectionFill,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: borderGray),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          p.imageUrl,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: primaryGreen),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                                            Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: primaryGreen, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(8)),
                                        child: Text('Eco ${p.ecoScore}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 36),

                    // Danger Zone: Store Removal
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD2D2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store_mall_directory_outlined, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Store Removal', style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  store.deletionRequested
                                      ? 'Removal request pending Admin approval'
                                      : 'Requires platform admin review & approval',
                                  style: const TextStyle(color: textGray, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!store.deletionRequested)
                            TextButton(
                              onPressed: () => showRequestDeletionDialog(store.id),
                              child: const Text('Request', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            )
                          else
                            TextButton(
                              onPressed: () => handleCancelDeletionRequest(store.id),
                              child: const Text('Cancel', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
