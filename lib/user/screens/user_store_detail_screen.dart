import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/store_detail_providers.dart';
import '../widgets/store_rating_dialog.dart';
import '../../admin/providers/store_list_providers.dart';
import 'web_view_screen.dart';

class UserStoreDetailScreen extends ConsumerStatefulWidget {
  final String storeId;

  const UserStoreDetailScreen({Key? key, required this.storeId}) : super(key: key);

  @override
  ConsumerState<UserStoreDetailScreen> createState() => UserStoreDetailScreenState();
}

class UserStoreDetailScreenState extends ConsumerState<UserStoreDetailScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);
  static const Color star = Color(0xFFF2B705);

  static const Color excellentColor = Color(0xFF1B7A43);
  static const Color goodColor = Color(0xFF5B9A4B);
  static const Color neutralColor = Color(0xFFB48A1F);
  static const Color poorColor = Color(0xFFC0452B);

  bool isLeaving = false;

  Future<void> openDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openWebsite(String website, String storeName) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: website, title: storeName)),
    );
  }

  Future<void> handleLeave(String storeName) async {
    if (isLeaving) return;
    isLeaving = true;

    final alreadyRated = await ref.read(hasUserRatedStoreProvider(widget.storeId).future);
    if (!mounted) return;

    if (!alreadyRated) {
      final rated = await showStoreRatingDialog(context, storeId: widget.storeId, storeName: storeName);
      if (rated) {
        ref.invalidate(storeByIdProvider(widget.storeId));
        ref.invalidate(hasUserRatedStoreProvider(widget.storeId));
        ref.invalidate(recentReviewsProvider(widget.storeId));
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  String initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  Color tierColor(int rating) {
    if (rating >= 5) return excellentColor;
    if (rating == 4) return goodColor;
    if (rating == 3) return neutralColor;
    return poorColor;
  }

  String tierLabel(int rating) {
    if (rating >= 5) return 'Excellent';
    if (rating == 4) return 'Great';
    if (rating == 3) return 'Good';
    return 'Needs improvement';
  }

  IconData tierIcon(int rating) {
    if (rating >= 4) return Icons.sentiment_very_satisfied_rounded;
    if (rating == 3) return Icons.sentiment_neutral_rounded;
    return Icons.sentiment_dissatisfied_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeByIdProvider(widget.storeId));
    final productsAsync = ref.watch(storeProductsProvider(widget.storeId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final storeName = storeAsync.asData?.value.name ?? 'this store';
        handleLeave(storeName);
      },
      child: Scaffold(
        backgroundColor: pureWhite,
        body: storeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
          error: (e, s) => Center(child: Text('Could not load store.\n$e', textAlign: TextAlign.center)),
          data: (store) {
            final isPhysical = store.storeType == 'physical';
            final hasCoordinates = store.latitude != null && store.longitude != null;
            final hasWebsite = store.website != null && store.website!.trim().isNotEmpty;

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => handleLeave(store.name),
                        icon: const Icon(Icons.arrow_back_rounded, color: textDark),
                      ),
                      Expanded(
                        child: Text(
                          store.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: textDark, fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      store.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 200,
                        color: sectionFill,
                        child: const Icon(Icons.storefront_rounded, color: textGray, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        isPhysical ? Icons.location_on_rounded : Icons.language_rounded,
                        size: 18,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isPhysical
                              ? (store.address ?? 'Address not available')
                              : (hasWebsite ? store.website! : 'Online store'),
                          style: const TextStyle(color: textDark, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (store.averageRating != null) ...[
                        const Icon(Icons.star_rounded, color: star, size: 20),
                        const SizedBox(width: 4),
                        Text(store.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 4),
                        Text('(${store.ratingCount} review${store.ratingCount == 1 ? '' : 's'})',
                            style: TextStyle(color: textGray.withOpacity(0.8), fontSize: 13)),
                      ] else
                        Text('No reviews yet', style: TextStyle(color: textGray.withOpacity(0.7), fontSize: 13)),
                    ],
                  ),
                  if (store.openingHours != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 16, color: textGray.withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Text(store.openingHours!, style: TextStyle(color: textGray.withOpacity(0.85), fontSize: 12.5)),
                      ],
                    ),
                  ],
                  if (store.description != null) ...[
                    const SizedBox(height: 14),
                    Text(store.description!, style: const TextStyle(color: textDark, fontSize: 13, height: 1.4)),
                  ],
                  const SizedBox(height: 24),
                  const Text('Products Available at This Store',
                      style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  productsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                    ),
                    error: (e, s) => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Could not load products.', style: TextStyle(color: textDark)),
                    ),
                    data: (products) {
                      if (products.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('No products listed yet.', style: TextStyle(color: textGray.withOpacity(0.7)))),
                        );
                      }
                      return SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: products.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return Container(
                              width: 110,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: pureWhite,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderGray),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      product.imageUrl,
                                      width: double.infinity,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        height: 60,
                                        color: sectionFill,
                                        child: const Icon(Icons.inventory_2_outlined, color: textGray, size: 20),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: textDark, fontWeight: FontWeight.w600, fontSize: 11.5)),
                                  const SizedBox(height: 2),
                                  Text('\$${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryGreen, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        // TODO: navigate to full "all products for this store" screen
                      },
                      child: const Text('View All Products', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  if (isPhysical && hasCoordinates) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => openDirections(store.latitude!, store.longitude!),
                        icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
                        label: const Text('Get Directions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ] else if (!isPhysical && hasWebsite) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => openWebsite(store.website!, store.name),
                        icon: const Icon(Icons.language_rounded, color: Colors.white, size: 18),
                        label: const Text('Visit Website', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                  Consumer(builder: (context, ref, _) {
                    final reviewsAsync = ref.watch(recentReviewsProvider(widget.storeId));
                    return reviewsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(child: CircularProgressIndicator(color: primaryGreen)),
                      ),
                      error: (e, s) => const SizedBox.shrink(),
                      data: (reviews) {
                        final withComments = reviews.where((r) => r.comment != null && r.comment!.isNotEmpty).toList();
                        if (withComments.isEmpty) return const SizedBox.shrink();

                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('What people say about this store', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
                                    child: Text('${withComments.length}',
                                        style: const TextStyle(color: primaryGreen, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              for (final review in withComments.take(8)) buildReviewCard(review),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildReviewCard(ReviewEntry review) {
    final color = tierColor(review.rating);
    final name = review.reviewerName ?? 'EcoWise user';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withOpacity(0.15),
                child: Text(initialsFor(name), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                              i < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: star,
                              size: 13,
                            )),
                        const SizedBox(width: 6),
                        Text(formatRelativeTime(review.createdAt), style: TextStyle(color: textGray.withOpacity(0.75), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tierIcon(review.rating), color: color, size: 13),
                    const SizedBox(width: 4),
                    Text(tierLabel(review.rating), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment!, style: const TextStyle(color: textDark, fontSize: 12.5, height: 1.45)),
        ],
      ),
    );
  }
}