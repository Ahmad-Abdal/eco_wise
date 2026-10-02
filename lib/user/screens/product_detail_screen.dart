import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scan_providers.dart';
import '../providers/wishlist_providers.dart';
import '../providers/compare_prices_providers.dart';
import 'compare_prices_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductDetail product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  int? storeCount;
  bool isTogglingWishlist = false;

  @override
  void initState() {
    super.initState();
    loadStoreCount();
  }

  Future<void> loadStoreCount() async {
    final comparison = await fetchPriceComparison(widget.product);
    if (!mounted) return;
    setState(() => storeCount = comparison.offers.length);
  }

  Future<void> toggleWishlist() async {
    setState(() => isTogglingWishlist = true);
    await ref.read(wishlistNotifierProvider.notifier).toggle(widget.product.id);
    if (!mounted) return;
    setState(() => isTogglingWishlist = false);
  }

  void openComparePrices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ComparePricesScreen(originalProduct: widget.product)),
    );
  }

  // Derives a handful of real keyword chips from this specific
  // product's actual attributes — never a fixed set, so a product
  // with different material/certification shows different chips.
  List<Map<String, dynamic>> buildKeywordChips() {
    final product = widget.product;
    final chips = <Map<String, dynamic>>[];

    if (product.material.trim().isNotEmpty && product.material.toLowerCase() != 'unknown') {
      chips.add({'label': product.material, 'icon': Icons.eco_outlined, 'tag': 'Material'});
    }
    if (product.reusable.toLowerCase() == 'yes') {
      chips.add({'label': 'Reusable', 'icon': Icons.autorenew_rounded, 'tag': 'Reuse'});
    }
    if (product.recyclable.toLowerCase() == 'yes') {
      chips.add({'label': 'Recyclable Packaging', 'icon': Icons.recycling_outlined, 'tag': 'Packaging'});
    }
    if (product.certification.toLowerCase().contains('certified')) {
      chips.add({'label': 'Certified', 'icon': Icons.verified_outlined, 'tag': 'Certification'});
    }
    return chips;
  }

  Color ecoScoreColor(int score) {
    if (score >= 80) return primaryGreen;
    if (score >= 50) return const Color(0xFFE0A429);
    return const Color(0xFFD3573C);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isWishlistedAsync = ref.watch(isWishlistedProvider(product.id));
    final isWishlisted = isWishlistedAsync.asData?.value ?? false;
    final keywordChips = buildKeywordChips();
    final scoreColor = ecoScoreColor(product.ecoScore);

    return Scaffold(
      backgroundColor: pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Hero image
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                        child: Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          height: 280,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(
                            height: 280,
                            color: sectionFill,
                            child: const Icon(Icons.inventory_2_outlined, color: textGray, size: 48),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.25), Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: pureWhite),
                            child: const Icon(Icons.arrow_back_rounded, color: textDark, size: 20),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: GestureDetector(
                          onTap: isTogglingWishlist ? null : toggleWishlist,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: pureWhite),
                            child: isTogglingWishlist
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen),
                                  )
                                : Icon(
                                    isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isWishlisted ? primaryGreen : textGray,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + brand
                        Text(product.name, style: const TextStyle(color: textDark, fontSize: 23, fontWeight: FontWeight.bold)),
                        if (product.brand != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
                            child: Text(product.brand!, style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w600, fontSize: 12)),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── Eco score card with progress bar — the
                        // piece that makes this product's sustainability
                        // rating actually visible at a glance, not just
                        // a number in a pill. ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scoreColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: scoreColor.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco_rounded, color: scoreColor, size: 18),
                                  const SizedBox(width: 6),
                                  const Text('Eco Score', style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                                  const Spacer(),
                                  Text('${product.ecoScore}/100', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: product.ecoScore / 100,
                                  minHeight: 8,
                                  backgroundColor: scoreColor.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation(scoreColor),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Price — its own clear line, biggest number on
                        // the page.
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text('Rs. ', style: TextStyle(color: textGray, fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(
                              product.price.toStringAsFixed(0),
                              style: const TextStyle(color: textDark, fontSize: 30, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        if (keywordChips.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Sustainability details', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.6,
                            children: keywordChips.map((chip) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: pureWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderGray),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
                                      child: Icon(chip['icon'] as IconData, color: primaryGreen, size: 17),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(chip['tag'] as String,
                                              style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 9.5, fontWeight: FontWeight.w600)),
                                          Text(
                                            chip['label'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: textDark, fontSize: 12.5, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        if (product.description != null) ...[
                          const SizedBox(height: 24),
                          const Text('Description', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 8),
                          Text(product.description!, style: const TextStyle(color: textGray, fontSize: 13, height: 1.55)),
                        ],

                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: openComparePrices,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: pureWhite,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: borderGray),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.storefront_outlined, color: primaryGreen, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    storeCount == null
                                        ? 'Checking availability...'
                                        : 'Available at $storeCount store${storeCount == 1 ? '' : 's'}',
                                    style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                                const Text('Compare', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                                const Icon(Icons.chevron_right_rounded, color: primaryGreen, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Persistent bottom action bar — outside the scroll
            // area, so it always sits at the true bottom of the screen
            // regardless of how short the content above is. This is
            // what fixes the "floating mid-screen" bug. ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: BoxDecoration(
                color: pureWhite,
                border: Border(top: BorderSide(color: borderGray)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isWishlisted ? lightGreenBg : pureWhite,
                          side: const BorderSide(color: primaryGreen, width: 1.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: isTogglingWishlist ? null : toggleWishlist,
                        icon: Icon(
                          isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: primaryGreen,
                          size: 18,
                        ),
                        label: Text(
                          isWishlisted ? 'Saved' : 'Add to Wishlist',
                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: openComparePrices,
                        icon: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 18),
                        label: const Text('Compare Prices', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}