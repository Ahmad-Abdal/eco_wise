import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_store_management_providers.dart';
import 'add_product_screen.dart';
import 'edit_store_screen.dart';
import 'manage_products_screen.dart';

class StoreDetailScreen extends ConsumerWidget {
  final String storeId;

  const StoreDetailScreen({Key? key, required this.storeId}) : super(key: key);

  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  void openStoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: primaryGreen),
                  title: const Text('Edit store', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditStoreScreen(storeId: storeId)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined, color: primaryGreen),
                  title: const Text('Manage products', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ManageProductsScreen(storeId: storeId)),
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
    final storeAsync = ref.watch(adminStoreDetailProvider(storeId));
    final ratingAsync = ref.watch(adminStoreRatingSummaryProvider(storeId));
    final productsAsync = ref.watch(adminStoreProductsProvider(storeId));

    return Scaffold(
      backgroundColor: pureWhite,
      body: SafeArea(
        child: storeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
          error: (error, stack) => const Center(
            child: Text('Could not load this store.', style: TextStyle(color: textDark)),
          ),
          data: (store) {
            if (store == null) {
              return const Center(
                child: Text('This store no longer exists.', style: TextStyle(color: textDark)),
              );
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    Image.network(
                      store.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 200,
                        color: sectionFill,
                        child: const Icon(Icons.storefront_outlined, color: textGray, size: 40),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: pureWhite),
                          child: const Icon(Icons.arrow_back_rounded, color: textDark, size: 20),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => openStoreMenu(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: pureWhite),
                          child: const Icon(Icons.more_vert_rounded, color: textDark, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name, style: const TextStyle(color: textDark, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            store.storeType == 'online' ? Icons.language_rounded : Icons.location_on_outlined,
                            color: textGray,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              store.storeType == 'online'
                                  ? (store.website ?? 'Online store')
                                  : (store.address ?? 'No address set'),
                              style: const TextStyle(color: textGray, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ratingAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                        data: (rating) {
                          if (rating.count == 0) {
                            return const Text('No ratings yet', style: TextStyle(color: textGray, fontSize: 13));
                          }
                          return Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${rating.average} (${rating.count} rating${rating.count == 1 ? '' : 's'})',
                                style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          );
                        },
                      ),
                      if (store.description != null) ...[
                        const SizedBox(height: 10),
                        Text(store.description!, style: const TextStyle(color: textDark, fontSize: 13, height: 1.4)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddProductScreen(storeId: store.id, storeName: store.name),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Products', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 17)),
                      const SizedBox(height: 12),
                      productsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                        ),
                        error: (error, stack) => const Text('Could not load products.', style: TextStyle(color: textDark)),
                        data: (products) {
                          if (products.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(16)),
                              child: const Center(
                                child: Text('No products added yet.', style: TextStyle(color: textGray)),
                              ),
                            );
                          }
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.78,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageProductsScreen(storeId: storeId),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: pureWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderGray),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Image.network(
                                          product.imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) => Container(
                                            color: sectionFill,
                                            child: const Icon(Icons.inventory_2_outlined, color: textGray),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  '\$${product.price.toStringAsFixed(0)}',
                                                  style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.eco, color: primaryGreen, size: 13),
                                                    Text(
                                                      '${product.ecoScore}',
                                                      style: const TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}