import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/services/ai_api_service.dart';
import '../providers/home_providers.dart';
import '../providers/scan_providers.dart';
import '../providers/scan_result_providers.dart';
import '../providers/wishlist_providers.dart';
import 'product_detail_screen.dart';
import 'search_results_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ScanScreen> createState() => ScanScreenState();
}

/// Colours for an eco score: green (80+), amber (50–79), red (below 50).
class EcoTier {
  final String label;
  final Color text;
  final Color bar;
  final Color track;
  final Color badgeFill;
  final Color cardFill;
  final Color cardBorder;

  const EcoTier({
    required this.label,
    required this.text,
    required this.bar,
    required this.track,
    required this.badgeFill,
    required this.cardFill,
    required this.cardBorder,
  });

  static EcoTier of(int score) {
    if (score >= 80) {
      return const EcoTier(
        label: 'Excellent',
        text: Color(0xFF1B7A43),
        bar: Color(0xFF1B7A43),
        track: Color(0xFFD7EEDF),
        badgeFill: Color(0xFFE7F4EC),
        cardFill: Color(0xFFF1F8F3),
        cardBorder: Color(0xFFCFE6D8),
      );
    }
    if (score >= 50) {
      return EcoTier(
        label: score >= 65 ? 'Good' : 'Fair',
        text: const Color(0xFF8A5A00),
        bar: const Color(0xFFE0A429),
        track: const Color(0xFFF6E7C4),
        badgeFill: const Color(0xFFFFF3D6),
        cardFill: const Color(0xFFFFFAEE),
        cardBorder: const Color(0xFFF1E1B8),
      );
    }
    return const EcoTier(
      label: 'Low',
      text: Color(0xFFB23B22),
      bar: Color(0xFFD3573C),
      track: Color(0xFFF5D9D1),
      badgeFill: Color(0xFFF8DDD5),
      cardFill: Color(0xFFFDF4F1),
      cardBorder: Color(0xFFF1D6CF),
    );
  }
}

class ScanScreenState extends ConsumerState<ScanScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF5F5F5F);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);
  static const Color scanGreen = Color(0xFF3FCF7E);

  final manualIdController = TextEditingController();
  final scannerController = MobileScannerController();

  bool isHandlingScan = false;
  bool isOpeningProduct = false;

  // Result state — null means the "ready to scan" view is showing.
  ProductDetail? scannedProduct;
  AlternativesResult? alternatives;
  bool isLoadingAlternatives = false;
  bool isLoadingMore = false;
  bool showingMore = false;

  // Ignores late server replies after the user tapped "Scan again".
  int requestId = 0;

  @override
  void dispose() {
    manualIdController.dispose();
    scannerController.dispose();
    super.dispose();
  }

  // ───────────────────────── scanning ─────────────────────────

  Future<void> safeStopScanner() async {
    try {
      await scannerController.stop();
    } catch (_) {}
  }

  Future<void> safeStartScanner() async {
    try {
      await scannerController.start();
    } catch (_) {}
  }

  Future<void> handleDetection(BarcodeCapture capture) async {
    if (isHandlingScan || scannedProduct != null) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    isHandlingScan = true;
    await safeStopScanner();
    await lookupAndShow(code);
  }

  /// Same lookup as before (finds the product and logs the scan),
  /// but the result now appears on this screen.
  Future<void> lookupAndShow(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      isHandlingScan = false;
      return;
    }
    FocusScope.of(context).unfocus();

    await ref.read(productLookupNotifierProvider.notifier).lookupProduct(trimmed);
    if (!mounted) return;

    final lookupState = ref.read(productLookupNotifierProvider);
    final product = lookupState.product;
    final error = lookupState.errorMessage;
    ref.read(productLookupNotifierProvider.notifier).reset();

    if (product != null) {
      ref.invalidate(recentScansProvider);
      ref.invalidate(userEcoScoreProvider); // Home's Eco-Score
      await showResult(product);
    } else {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      isHandlingScan = false;
      await safeStartScanner();
    }
  }

  Future<void> showResult(ProductDetail product) async {
    await safeStopScanner();
    final id = ++requestId;
    setState(() {
      scannedProduct = product;
      alternatives = null;
      isLoadingAlternatives = true;
      isLoadingMore = false;
      showingMore = false;
    });
    manualIdController.clear();

    final result = await AiApiService.fetchGreenerAlternatives(product.id, limit: 3);
    if (!mounted || id != requestId) return;
    setState(() {
      alternatives = result;
      isLoadingAlternatives = false;
    });
  }

  Future<void> loadMoreAlternatives() async {
    final product = scannedProduct;
    if (product == null || isLoadingMore) return;
    final id = requestId;
    setState(() => isLoadingMore = true);

    final result = await AiApiService.fetchGreenerAlternatives(product.id, limit: 10);
    if (!mounted || id != requestId) return;
    setState(() {
      isLoadingMore = false;
      if (result.serverReachable) {
        alternatives = result;
        showingMore = true;
      }
    });
    if (!result.serverReachable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load more alternatives right now.')),
      );
    }
  }

  Future<void> scanAgain() async {
    requestId++;
    setState(() {
      scannedProduct = null;
      alternatives = null;
      isLoadingAlternatives = false;
      isLoadingMore = false;
      showingMore = false;
    });
    isHandlingScan = false;
    await safeStartScanner();
  }

  // ───────────────────────── navigation ─────────────────────────

  void openDetails(ProductDetail product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
    );
  }

  Future<void> openProductById(String productId) async {
    if (isOpeningProduct) return;
    isOpeningProduct = true;
    final detail = await fetchProductById(productId);
    isOpeningProduct = false;
    if (!mounted) return;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load this product.')),
      );
      return;
    }
    openDetails(detail);
  }

  /// Tapping a recent scan shows its result again (without logging a new scan).
  Future<void> openRecentScan(RecentScan scan) async {
    if (isOpeningProduct) return;
    isOpeningProduct = true;
    final detail = await fetchProductById(scan.productId);
    isOpeningProduct = false;
    if (!mounted) return;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load this product.')),
      );
      return;
    }
    isHandlingScan = true;
    await showResult(detail);
  }

  void exploreCategory(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchResultsScreen(initialQuery: '', category: category)),
    );
  }

  // ───────────────────────── small pieces ─────────────────────────

  Widget productImage(String url, double size, {Color fill = sectionFill, Color iconColor = primaryGreen}) {
    final placeholder = Container(
      width: size,
      height: size,
      color: fill,
      child: Icon(Icons.inventory_2_outlined, color: iconColor, size: size * 0.42),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => placeholder,
            ),
    );
  }

  Widget ecoBadge(int score) {
    final tier = EcoTier.of(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: tier.badgeFill, borderRadius: BorderRadius.circular(8)),
      child: Text('$score Eco', style: TextStyle(color: tier.text, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  String priceText(double price) => 'Rs. ${price.toStringAsFixed(0)}';

  List<String> productChips(ProductDetail product) {
    final chips = <String>[];
    final material = product.material.trim();
    if (material.isNotEmpty && material.toLowerCase() != 'unknown') chips.add(material);
    final reusable = product.reusable.toLowerCase();
    if (reusable == 'yes') chips.add('Reusable');
    if (reusable == 'no') chips.add('Not reusable');
    final certification = product.certification.toLowerCase();
    if (certification.contains('certified') && !certification.startsWith('not')) chips.add('Certified');
    return chips;
  }

  Widget sectionTitle(String text) {
    return Text(text, style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold));
  }

  // ───────────────────────── headers ─────────────────────────

  Widget buildIdleHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.qr_code_scanner_rounded, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan & Save', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 22)),
              SizedBox(height: 2),
              Text('Scan a product to see greener swaps', style: TextStyle(color: textGray, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildResultHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan result', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 22)),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.check_rounded, color: primaryGreen, size: 15),
                  SizedBox(width: 4),
                  Text('Scanned just now', style: TextStyle(color: textGray, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryGreen, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: scanAgain,
            icon: const Icon(Icons.qr_code_scanner_rounded, color: primaryGreen, size: 18),
            label: const Text('Scan again', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── ready-to-scan view ─────────────────────────

  Widget buildScanner(bool isLoading) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 290,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: scannerController, onDetect: handleDetection),
            IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 196,
                  height: 196,
                  child: CustomPaint(
                    painter: ScanFramePainter(color: scanGreen),
                    child: Center(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: scanGreen,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [BoxShadow(color: scanGreen.withOpacity(0.55), blurRadius: 14, spreadRadius: 2)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: IgnorePointer(
                child: Text(
                  'Align the product QR code inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFD6E9DD), fontSize: 13),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white.withOpacity(0.12),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Flashlight',
                  onPressed: () => scannerController.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.45),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildIdleBody(bool isLoading) {
    return [
      const SizedBox(height: 22),
      const Text('Or enter product ID', style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: manualIdController,
              style: const TextStyle(color: textDark, fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: isLoading ? null : (value) => lookupAndShow(value),
              decoration: InputDecoration(
                hintText: 'Enter product ID',
                hintStyle: const TextStyle(color: textGray),
                filled: true,
                fillColor: sectionFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderGray)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderGray)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: isLoading ? null : () => lookupAndShow(manualIdController.text),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          Expanded(child: sectionTitle('Recent scans')),
        ],
      ),
      const SizedBox(height: 12),
      buildRecentScans(),
    ];
  }

  Widget buildRecentScans() {
    final recentAsync = ref.watch(recentScansProvider);
    return recentAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2.4)),
      ),
      error: (error, stack) => const SizedBox.shrink(),
      data: (scans) {
        if (scans.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Icon(Icons.history_rounded, color: textGray.withOpacity(0.7), size: 28),
                const SizedBox(height: 8),
                const Text(
                  'Products you scan will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textGray, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return Column(
          children: scans.map((scan) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: pureWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: borderGray),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => openRecentScan(scan),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        productImage(scan.imageUrl, 48, fill: lightGreenBg),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(scan.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(
                                [if (scan.brand != null) scan.brand!, priceText(scan.price)].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: textGray, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ecoBadge(scan.ecoScore),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ───────────────────────── result view ─────────────────────────

  List<Widget> buildResultBody(ProductDetail product) {
    return [
      buildScannedCard(product),
      const SizedBox(height: 22),
      ...buildAlternativesSection(product),
    ];
  }

  Widget buildScannedCard(ProductDetail product) {
    final tier = EcoTier.of(product.ecoScore);
    final chips = productChips(product);
    final subtitle = [if (product.brand != null) product.brand!, if (product.category != null) product.category!].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tier.cardFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tier.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              productImage(product.imageUrl, 88, fill: pureWhite, iconColor: tier.text),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOU SCANNED',
                        style: TextStyle(color: tier.text, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                    const SizedBox(height: 4),
                    Text(product.name, style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(color: textGray, fontSize: 12)),
                    ],
                    const SizedBox(height: 6),
                    Text(priceText(product.price),
                        style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.eco_rounded, color: tier.text, size: 17),
              const SizedBox(width: 6),
              const Text('Eco Score', style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: tier.badgeFill, borderRadius: BorderRadius.circular(8)),
                child: Text(tier.label, style: TextStyle(color: tier.text, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text('${product.ecoScore}/100', style: TextStyle(color: tier.text, fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: product.ecoScore / 100,
              minHeight: 8,
              backgroundColor: tier.track,
              valueColor: AlwaysStoppedAnimation(tier.bar),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: chips.map((chip) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: pureWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tier.cardBorder),
                      ),
                      child: Text(chip, style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                ),
              ),
              TextButton(
                onPressed: () => openDetails(product),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Details', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                    Icon(Icons.chevron_right_rounded, color: primaryGreen, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildAlternativesHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: primaryGreen, size: 20),
            const SizedBox(width: 8),
            Expanded(child: sectionTitle('Greener alternatives')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
              child: const Text('AI match', style: TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Same kind of product, better for the planet', style: TextStyle(color: textGray, fontSize: 12.5)),
        const SizedBox(height: 14),
      ],
    );
  }

  List<Widget> buildAlternativesSection(ProductDetail product) {
    if (isLoadingAlternatives) {
      return [
        buildAlternativesHeader(),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 26),
          decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(20)),
          child: const Column(
            children: [
              SizedBox(width: 26, height: 26, child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2.6)),
              SizedBox(height: 12),
              Text('Finding greener alternatives…', style: TextStyle(color: textGray, fontSize: 13)),
            ],
          ),
        ),
      ];
    }

    final result = alternatives;
    if (result == null) return [];

    if (!result.serverReachable) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(20)),
          child: const Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: textGray, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Greener alternatives are unavailable right now. Please try again later.',
                  style: TextStyle(color: textGray, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    if (result.alternatives.isEmpty) return buildTopPick(product);

    final list = result.alternatives;
    return [
      buildAlternativesHeader(),
      for (var i = 0; i < list.length; i++) buildAlternativeCard(list[i], isBest: i == 0),
      if (!showingMore && list.length >= 3)
        SizedBox(
          height: 48,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: sectionFill,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: isLoadingMore ? null : loadMoreAlternatives,
            child: isLoadingMore
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryGreen, strokeWidth: 2.4))
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View more alternatives', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 13.5)),
                      Icon(Icons.chevron_right_rounded, color: primaryGreen, size: 18),
                    ],
                  ),
          ),
        ),
    ];
  }

  Widget buildAlternativeCard(GreenerAlternative alt, {required bool isBest}) {
    final subtitle = [if (alt.brand != null) alt.brand!, priceText(alt.price)].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBest ? primaryGreen : borderGray, width: isBest ? 1.5 : 1),
        boxShadow: isBest
            ? [BoxShadow(color: primaryGreen.withOpacity(0.10), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: Row(
        children: [
          productImage(alt.imageUrl, 64, fill: isBest ? lightGreenBg : sectionFill),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBest) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(8)),
                    child: const Text('BEST SWAP',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(alt.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: textGray, fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ecoBadge(alt.ecoScore),
                    Text('+${alt.ecoGain} greener',
                        style: const TextStyle(color: primaryGreen, fontSize: 11.5, fontWeight: FontWeight.w700)),
                    Text('· ${alt.matchPercent}% match', style: const TextStyle(color: textGray, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: isBest
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => openProductById(alt.id),
                    child: const Text('View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  )
                : OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryGreen, width: 1.4),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => openProductById(alt.id),
                    child: const Text('View', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildTopPick(ProductDetail product) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            const Text('Great choice!', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              'This is already the greenest option among similar products. No better swap found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFE2F2E8), fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      Consumer(builder: (context, ref, _) {
        final isWishlisted = ref.watch(isWishlistedProvider(product.id)).asData?.value ?? false;
        return SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: isWishlisted ? lightGreenBg : primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => ref.read(wishlistNotifierProvider.notifier).toggle(product.id),
            icon: Icon(
              isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isWishlisted ? primaryGreen : Colors.white,
              size: 18,
            ),
            label: Text(
              isWishlisted ? 'Saved to Wishlist' : 'Add to Wishlist',
              style: TextStyle(
                color: isWishlisted ? primaryGreen : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        );
      }),
      if (product.category != null) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryGreen, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => exploreCategory(product.category!),
            child: Text(
              'Explore ${product.category}',
              style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    ];
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final lookupState = ref.watch(productLookupNotifierProvider);
    final product = scannedProduct;

    return Scaffold(
      backgroundColor: pureWhite,
      body: SafeArea(
        child: ListView(
          // Bottom space keeps the last card clear of the chat button.
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            product == null ? buildIdleHeader() : buildResultHeader(),
            const SizedBox(height: 18),
            // The scanner stays mounted (just hidden) while a result shows,
            // so "Scan again" can restart it exactly like before.
            Offstage(offstage: product != null, child: buildScanner(lookupState.isLoading)),
            if (product == null) ...buildIdleBody(lookupState.isLoading) else ...buildResultBody(product),
          ],
        ),
      ),
    );
  }
}

/// Draws the four rounded corner brackets of the scan frame.
class ScanFramePainter extends CustomPainter {
  final Color color;

  const ScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 36.0;
    const r = 18.0;
    final w = size.width;
    final h = size.height;
    const radius = Radius.circular(r);

    final path = Path()
      ..moveTo(0, len)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: radius)
      ..lineTo(len, 0)
      ..moveTo(w - len, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: radius)
      ..lineTo(w, len)
      ..moveTo(w, h - len)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: radius)
      ..lineTo(w - len, h)
      ..moveTo(len, h)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: radius)
      ..lineTo(0, h - len);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScanFramePainter oldDelegate) => oldDelegate.color != color;
}