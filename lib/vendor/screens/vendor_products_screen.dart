import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/models/product.dart';
import '../../admin/models/store.dart';
import '../providers/vendor_dashboard_providers.dart';
import 'vendor_add_product_screen.dart';
import 'vendor_edit_product_screen.dart';

class VendorProductsScreen extends ConsumerWidget {
  final Store store;

  const VendorProductsScreen({Key? key, required this.store}) : super(key: key);

  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  Future<void> handleDeleteProduct(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: pureWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product?', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${product.name}"? This product will no longer appear to users.',
          style: const TextStyle(color: textGray, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(vendorStoreControllerProvider).deleteProduct(product.id!, store.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${product.name}" has been deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete product: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorStoreProductsProvider(store.id));

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text('My Products', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: lightGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: primaryGreen),
              tooltip: 'Add product',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorAddProductScreen(storeId: store.id, storeName: store.name),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryGreen,
          onRefresh: () async => ref.invalidate(vendorStoreProductsProvider(store.id)),
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
            error: (e, _) => Center(child: Text('Error loading products: $e', style: const TextStyle(color: textDark))),
            data: (products) {
              if (products.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: lightGreenBg),
                        child: const Icon(Icons.inventory_2_outlined, size: 38, color: primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text('No products in your store yet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark)),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text('Tap the + button above to add your first eco-product.', style: TextStyle(color: textGray, fontSize: 13)),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
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
                            p.imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: sectionFill,
                              child: const Icon(Icons.eco_rounded, color: primaryGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
                              ),
                              const SizedBox(height: 4),
                              Text('\$${p.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryGreen)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                      'Eco: ${p.ecoScore}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryGreen),
                                    ),
                                  ),
                                  if (p.category != null)
                                    Text(
                                      p.category!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: textGray),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Actions
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: textDark, size: 20),
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => VendorEditProductScreen(productId: p.id!)),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete',
                          onPressed: () => handleDeleteProduct(context, ref, p),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
