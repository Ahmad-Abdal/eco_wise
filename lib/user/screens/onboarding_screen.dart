import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/categories.dart';
import '../providers/onboarding_providers.dart';
import 'user_home_shell.dart';

const _categoryEmojis = {
  'Cleaning': '🧹',
  'Kitchen Accessories': '🍽️',
  'Home & Living': '🏠',
  'Personal Care': '🧴',
  'Fashion': '👕',
  'Laundry': '🧺',
  'Shopping': '🛍️',
  'Storage': '📦',
  'Dining': '🍱',
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  final pageController = PageController();
  int currentPage = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void goToNextPage() {
    pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void goToPreviousPage() {
    pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  Future<void> finishOnboarding({required bool skip}) async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final success = skip ? await notifier.skipOnboarding() : await notifier.savePreferences();

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const UserHomeShell()),
        (route) => false,
      );
    } else {
      final error = ref.read(onboardingNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Something went wrong. Please try again.')),
      );
    }
  }

  Widget buildProgressDots() {
    return Row(
      children: List.generate(2, (index) {
        final isActive = index == currentPage;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? primaryGreen : borderGray,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget buildMultiSelectChip({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : sectionFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? primaryGreen : borderGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPageHeader({required String title, required String subtitle, bool showBack = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: goToPreviousPage,
              child: const Icon(Icons.arrow_back_rounded, color: textDark),
            ),
          ),
        Text(title, style: const TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: textGray, fontSize: 14)),
      ],
    );
  }

  Widget buildCategoriesPage() {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPageHeader(
            title: 'What would you like to discover?',
            subtitle: 'Pick as many as you like — you can change this anytime.',
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: productCategories.map((category) {
                  final selected = state.selectedCategories.contains(category);
                  return buildMultiSelectChip(
                    emoji: _categoryEmojis[category] ?? '🌱',
                    label: category,
                    selected: selected,
                    onTap: () => notifier.toggleCategory(category),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: goToNextPage,
              child: const Text('Next', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPricePage() {
    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    const descriptions = {
      'Budget': 'Show me the most affordable options first.',
      'Moderate': 'A balance of price and quality.',
      'Premium': 'Quality and sustainability first, price second.',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildPageHeader(
            title: "What's your preferred price range?",
            subtitle: 'You can shop outside this anytime.',
            showBack: true,
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView(
              children: pricePreferenceOptions.map((option) {
                final selected = state.pricePreference == option;
                return GestureDetector(
                  onTap: () => notifier.setPricePreference(option),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? lightGreenBg : sectionFill,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? primaryGreen : borderGray, width: selected ? 1.4 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: selected ? primaryGreen : textGray,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(option, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(descriptions[option]!, style: const TextStyle(color: textGray, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: state.isSaving ? null : () => finishOnboarding(skip: false),
              child: state.isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildProgressDots(),
                  TextButton(
                    onPressed: () => finishOnboarding(skip: true),
                    child: const Text('Skip', style: TextStyle(color: textGray, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => currentPage = index),
                children: [
                  buildCategoriesPage(),
                  buildPricePage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}