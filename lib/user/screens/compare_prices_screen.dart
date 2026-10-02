import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/compare_prices_providers.dart';
import '../providers/scan_providers.dart';

class ComparePricesScreen extends StatefulWidget {
  final ProductDetail originalProduct;

  const ComparePricesScreen({Key? key, required this.originalProduct}) : super(key: key);

  @override
  State<ComparePricesScreen> createState() => ComparePricesScreenState();
}

enum ComparisonSort { byPrice, byDistance }

class ComparePricesScreenState extends State<ComparePricesScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  bool isLoading = true;
  CompareResult? result;
  ComparisonSort sort = ComparisonSort.byPrice;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final comparison = await fetchPriceComparison(widget.originalProduct);
    if (!mounted) return;
    setState(() {
      result = comparison;
      isLoading = false;
    });
  }

  Future<void> openDirections(StoreOffer offer) async {
    final store = offer.product.store;

    // Online stores (or any store missing coordinates) have nothing to
    // navigate to — open their website link instead, if they have one.
    if (store.latitude == null || store.longitude == null) {
      if (store.website != null && store.website!.trim().isNotEmpty) {
        final websiteUrl = Uri.tryParse(store.website!.trim());
        if (websiteUrl != null) {
          await launchUrl(websiteUrl, mode: LaunchMode.externalApplication);
        }
      }
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${store.latitude},${store.longitude}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  List<StoreOffer> get sortedOffers {
    final offers = List<StoreOffer>.from(result?.offers ?? []);
    if (sort == ComparisonSort.byPrice) {
      offers.sort((a, b) => a.product.price.compareTo(b.product.price));
    } else {
      offers.sort((a, b) {
        final aDist = a.distanceKm ?? double.infinity;
        final bDist = b.distanceKm ?? double.infinity;
        return aDist.compareTo(bDist);
      });
    }
    return offers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text(
          'Price Comparison',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : buildBody(),
      ),
    );
  }

  Widget buildBody() {
    final comparison = result;
    if (comparison == null || !comparison.hasAlternatives) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_outlined, color: textGray.withOpacity(0.6), size: 40),
              const SizedBox(height: 14),
              const Text(
                'This product is not available at any other store.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textGray, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final offers = sortedOffers;
    final best = comparison.bestPriceOffer;
    final savingsAmount = comparison.savingsAmount;
    final savingsPercent = comparison.savingsPercent;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                comparison.offers.first.product.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 56,
                  height: 56,
                  color: sectionFill,
                  child: const Icon(Icons.inventory_2_outlined, color: textGray),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.originalProduct.name,
                    style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (widget.originalProduct.brand != null)
                    Text(widget.originalProduct.brand!, style: const TextStyle(color: textGray, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.eco, color: primaryGreen, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Eco Score ${widget.originalProduct.ecoScore}',
                        style: const TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(child: buildSortTab('By Price', ComparisonSort.byPrice)),
              Expanded(child: buildSortTab('By Distance', ComparisonSort.byDistance)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final offer in offers) buildOfferCard(offer, isBest: offer.product.storeId == best?.product.storeId),
        if (best != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: primaryGreen, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Best Price', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(
                        '${best.product.store.name} - Rs. ${best.product.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: textDark, fontSize: 13),
                      ),
                      if (savingsAmount != null && savingsPercent != null)
                        Text(
                          'You save Rs. ${savingsAmount.toStringAsFixed(0)} (${savingsPercent.toStringAsFixed(0)}%)',
                          style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget buildSortTab(String label, ComparisonSort value) {
    final selected = sort == value;
    return GestureDetector(
      onTap: () => setState(() => sort = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : textGray,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget buildOfferCard(StoreOffer offer, {required bool isBest}) {
    final store = offer.product.store;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBest ? primaryGreen : borderGray, width: isBest ? 1.4 : 1),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: sectionFill,
                    child: const Icon(Icons.storefront_rounded, color: primaryGreen),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.name, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (offer.distanceKm != null) ...[
                            const Icon(Icons.location_on_outlined, color: textGray, size: 13),
                            const SizedBox(width: 2),
                            Text('${offer.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(color: textGray, fontSize: 12)),
                            const SizedBox(width: 8),
                          ],
                          const Icon(Icons.eco, color: primaryGreen, size: 13),
                          const SizedBox(width: 2),
                          Text('Eco Score ${offer.product.ecoScore}', style: const TextStyle(color: primaryGreen, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs. ${offer.product.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => openDirections(offer),
                          child: Text(
                            store.latitude != null && store.longitude != null ? 'Get Directions' : 'Visit Website',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isBest)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.only(topRight: Radius.circular(14), bottomLeft: Radius.circular(14)),
                ),
                child: const Text('Best Price', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}