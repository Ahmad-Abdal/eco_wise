import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_store_management_providers.dart';
import '../providers/dashboard_providers.dart';
import 'edit_product_screen.dart';

class ManageProductsScreen extends ConsumerWidget {
  final String storeId;

  const ManageProductsScreen({Key? key, required this.storeId}) : super(key: key);

  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  Future<void> handleDelete(BuildContext context, WidgetRef ref, AdminProductSummary product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this product?', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Text(
          '"${product.name}" will be permanently removed and will no longer be visible to users. '
          'This cannot be undone.',
          style: const TextStyle(color: textGray, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: textGray, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await deleteProduct(product.id);
      ref.invalidate(adminStoreProductsProvider(storeId));
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(storesOverviewProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete product: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminStoreProductsProvider(storeId));

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('Manage products', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
          error: (error, stack) => const Center(
            child: Text('Could not load products.', style: TextStyle(color: textDark)),
          ),
          data: (products) {
            if (products.isEmpty) {
              return const Center(
                child: Text('No products added yet.', style: TextStyle(color: textGray)),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderGray),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            width: 60,
                            height: 60,
                            color: sectionFill,
                            child: const Icon(Icons.inventory_2_outlined, color: textGray),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.eco, color: primaryGreen, size: 13),
                                    Text(
                                      ' ${product.ecoScore}',
                                      style: const TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditProductScreen(productId: product.id)),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, color: primaryGreen, size: 20),
                      ),
                      IconButton(
                        onPressed: () => handleDelete(context, ref, product),
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      ),
                    ],
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