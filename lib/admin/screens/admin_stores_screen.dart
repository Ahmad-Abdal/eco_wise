import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/store_list_providers.dart';
import 'store_detail_screen.dart';
import 'add_store_screen.dart';

class AdminStoresScreen extends ConsumerWidget {
  const AdminStoresScreen({Key? key}) : super(key: key);

  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storesAsync = ref.watch(storeListProvider);

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        title: const Text('Stores', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: lightGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_business_rounded, color: primaryGreen),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStoreScreen()),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: () async => ref.invalidate(storeListProvider),
        child: storesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
          error: (error, stack) => ListView(
            children: [
              const SizedBox(height: 80),
              Center(
                child: Text('Could not load stores.\n$error',
                    textAlign: TextAlign.center, style: const TextStyle(color: textDark)),
              ),
            ],
          ),
          data: (stores) {
            if (stores.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: lightGreenBg,
                        border: Border.all(color: borderGray, width: 1),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 40, color: primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text('No stores yet', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Tap + above to add your first store.', style: TextStyle(color: textGray)),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StoreDetailScreen(storeId: store.id)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sectionFill,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderGray, width: 1),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            store.imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 64,
                              height: 64,
                              color: lightGreenBg,
                              child: const Icon(Icons.storefront_rounded, color: primaryGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(store.name,
                                  style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: textGray),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      store.address ?? 'Address unavailable',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: textGray, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (store.averageRating != null) ...[
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF2B705)),
                                    const SizedBox(width: 2),
                                    Text(store.averageRating!.toStringAsFixed(1),
                                        style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 12)),
                                    Text(' (${store.ratingCount})',
                                        style: TextStyle(color: textGray, fontSize: 11)),
                                  ] else
                                    Text('No ratings yet',
                                        style: TextStyle(color: textGray, fontSize: 11)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.inventory_2_outlined, size: 14, color: textGray),
                                  const SizedBox(width: 3),
                                  Text('${store.productCount} products',
                                      style: TextStyle(color: textGray, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: textGray),
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