import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/browse_providers.dart';
import 'search_results_screen.dart';
import 'all_categories_screen.dart';
import 'package:ecowise/user/screens/sustainability_tips_screen.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BrowseScreen> createState() => BrowseScreenState();
}

const _homeGridOrder = [
  'Fashion',
  'Cleaning',
  'Home & Living',
  'Storage',
  'Personal Care',
  'Dining',
];

class BrowseScreenState extends ConsumerState<BrowseScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void submitSearch(String query) {
    if (query.trim().isEmpty) return;
    logSearchTerm(query);
    ref.invalidate(popularSearchesProvider);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchResultsScreen(initialQuery: query)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final popularSearchesAsync = ref.watch(popularSearchesProvider);
    final gridCategories = _homeGridOrder
        .map((name) => browseCategories.firstWhere((c) => c.name == name))
        .toList();

    return Scaffold(
      backgroundColor: pureWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Browse Categories',
                  style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllCategoriesScreen()),
                    );
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final category = gridCategories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchResultsScreen(
                          initialQuery: '',
                          category: category.name,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: sectionFill,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              category.assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) => const Icon(
                                Icons.image_outlined,
                                color: textGray,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
            popularSearchesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (terms) {
                if (terms.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Popular Searches',
                        style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: terms.map((term) {
                          return GestureDetector(
                            onTap: () {
                              searchController.text = term;
                              submitSearch(term);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: pureWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderGray),
                              ),
                              child: Text(
                                term,
                                style: const TextStyle(color: textGray, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const SustainabilityTipsScreen(),
  ),
);
                // TODO: wire up the "Make Better Choices" destination
                // in a later step.
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightGreenBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: pureWhite),
                      child: const Icon(Icons.eco_rounded, color: primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make Better Choices',
                            style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Good for you. Good for the planet.',
                            style: TextStyle(color: textGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: textGray),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}