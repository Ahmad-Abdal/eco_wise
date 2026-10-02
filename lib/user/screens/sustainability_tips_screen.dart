import 'package:flutter/material.dart';

/// EcoWise Sustainability Tips
///
/// This file keeps the sustainability-tip data directly inside Dart.
/// No separate JSON asset is required.
///
/// Categories:
/// Cleaning, Kitchen Accessories, Home & Living, Personal Care,
/// Fashion, Laundry, Shopping, Storage, Dining
///
/// The selected category can be changed using the chips at the top.
/// "All" shows tips from all categories.
///
/// The tip order is rotated using the current day, so the first tip
/// shown for a category can change every 24 hours.

class SustainabilityTip {
  final String title;
  final String summary;
  final List<String> details;

  const SustainabilityTip({
    required this.title,
    required this.summary,
    required this.details,
  });
}

class SustainabilityCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<SustainabilityTip> tips;

  const SustainabilityCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.tips,
  });
}

class SustainabilityTipsScreen extends StatefulWidget {
  const SustainabilityTipsScreen({super.key});

  @override
  State<SustainabilityTipsScreen> createState() =>
      _SustainabilityTipsScreenState();
}

class _SustainabilityTipsScreenState extends State<SustainabilityTipsScreen> {
  String selectedCategory = 'All';

  // Change this date only if you want to reset the daily rotation.
  final DateTime rotationStartDate = DateTime(2026, 1, 1);

  static const List<SustainabilityCategory> categories = [
    // -----------------------------------------------------------------------
    // CLEANING
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Cleaning',
      icon: Icons.cleaning_services_outlined,
      color: Color(0xFF2A8C82),
      tips: [
        SustainabilityTip(
          title: 'Reusable Cleaning Tools',
          summary:
              'Choose reusable cleaning tools instead of disposable ones.',
          details: [
            'Swap paper towels for washable cloths or microfibre cloths.',
            'Pick sponges and brushes with replaceable heads.',
            'Wash and air-dry cloths so they last longer.',
          ],
        ),
        SustainabilityTip(
          title: "Refill, Don't Rebuy",
          summary:
              'Look for concentrated or refillable cleaning products to reduce packaging.',
          details: [
            'Concentrates use less packaging for the same number of uses.',
            'Keep the original bottle and refill it instead of buying a new one.',
            'Check whether a local store offers refill stations.',
          ],
        ),
        SustainabilityTip(
          title: 'Mind the Packaging',
          summary:
              'Prefer products with recyclable or minimal packaging.',
          details: [
            'Look for recyclable labels and check your local recycling rules.',
            'Avoid heavily layered or mixed-material packs that are hard to recycle.',
            'Buy a larger size only if you will use it before it expires.',
          ],
        ),
        SustainabilityTip(
          title: 'Use Less, Clean Just as Well',
          summary:
              'Most cleaning jobs need far less product than people tend to use.',
          details: [
            'Follow the dosage printed on the label.',
            'Wipe off heavy dirt with a cloth before applying product.',
            'Using too much also means more rinsing and more waste.',
          ],
        ),
        SustainabilityTip(
          title: 'Look for Gentler Formulas',
          summary:
              'Choose cleaners with clear ingredient lists and recognised eco labels.',
          details: [
            'Prefer products that list their ingredients openly.',
            'Recognised third-party eco labels are more reliable than vague claims.',
            'Never mix different cleaning products together.',
          ],
        ),
        SustainabilityTip(
          title: 'Make Your Tools Last',
          summary:
              'Caring for your cleaning tools means fewer replacements.',
          details: [
            'Rinse and dry brushes and mops after each use.',
            'Replace only the worn part, not the whole tool.',
            'Turn worn-out cloths into rags before throwing them away.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // KITCHEN ACCESSORIES
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Kitchen Accessories',
      icon: Icons.kitchen_outlined,
      color: Color(0xFFD9822B),
      tips: [
        SustainabilityTip(
          title: 'Durable Over Disposable',
          summary:
              'Choose durable, reusable kitchen tools instead of disposable alternatives.',
          details: [
            'Stainless steel, glass, and wooden tools can last for years.',
            'Reusable containers replace single-use wraps and bags.',
            'One good tool often replaces several cheap ones.',
          ],
        ),
        SustainabilityTip(
          title: 'Reusable and Recyclable Materials',
          summary: 'Prefer materials that are reusable and recyclable.',
          details: [
            'Stainless steel and glass are widely recyclable.',
            'Check the material label before you buy.',
            'Avoid mixed-material items that are difficult to recycle.',
          ],
        ),
        SustainabilityTip(
          title: 'Skip Single-Use Plastics',
          summary:
              'Avoid unnecessary single-use plastic items in the kitchen.',
          details: [
            'Swap plastic wrap for lidded containers or beeswax wraps.',
            'Use cloth or reusable produce bags.',
            'Carry a reusable straw and cutlery for meals on the go.',
          ],
        ),
        SustainabilityTip(
          title: 'Pick Tools You Can Repair',
          summary:
              'Choose tools with replaceable parts rather than throwaway designs.',
          details: [
            'Look for replaceable blades, lids, and seals.',
            'Keep spare parts instead of replacing the whole item.',
            'Handles and hinges that can be tightened last longer.',
          ],
        ),
        SustainabilityTip(
          title: 'Care for Your Gear',
          summary:
              'Proper care keeps wood, cast iron, and steel in use for years.',
          details: [
            'Dry wooden boards fully and oil them from time to time.',
            'Season cast iron to prevent rust.',
            'Avoid harsh scouring that damages surfaces.',
          ],
        ),
        SustainabilityTip(
          title: 'Buy Only What You Will Use',
          summary:
              'A small set of well-chosen tools beats a drawer full of gadgets.',
          details: [
            'Skip single-purpose gadgets you will rarely use.',
            'Borrow or share tools you only need occasionally.',
            'Choose multi-purpose items where you can.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // HOME & LIVING
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Home & Living',
      icon: Icons.home_outlined,
      color: Color(0xFF3B82B6),
      tips: [
        SustainabilityTip(
          title: 'Buy to Last, Repair to Keep',
          summary:
              'Choose durable products that can be repaired instead of replaced.',
          details: [
            'Look for sturdy joints, solid materials, and replaceable parts.',
            'Learn simple fixes like tightening screws or re-gluing.',
            'Buy from brands that offer spare parts.',
          ],
        ),
        SustainabilityTip(
          title: 'Recycled and Renewable Materials',
          summary:
              'Look for products made from recycled or renewable materials.',
          details: [
            'Bamboo, responsibly sourced wood, and recycled glass are good options.',
            'Recycled fabrics work well for cushions and covers.',
            'Be cautious of vague eco claims with no detail behind them.',
          ],
        ),
        SustainabilityTip(
          title: 'Less Packaging, Less Waste',
          summary: 'Avoid products with excessive packaging.',
          details: [
            'Choose items that ship with minimal or recyclable packaging.',
            'Reuse boxes and padding for storage or shipping.',
            'Buy in person when possible to skip shipping materials.',
          ],
        ),
        SustainabilityTip(
          title: 'Save Energy at Home',
          summary:
              'Small habits reduce energy use without changing how you live.',
          details: [
            'Switch to LED bulbs.',
            'Unplug chargers and devices you are not using.',
            'Use natural light and fresh air whenever possible.',
          ],
        ),
        SustainabilityTip(
          title: 'Buy Second-Hand First',
          summary:
              'Pre-owned furniture and decor often cost less and save resources.',
          details: [
            'Check local marketplaces and thrift stores.',
            'Refinish or reupholster instead of replacing.',
            'Donate items you no longer need.',
          ],
        ),
        SustainabilityTip(
          title: 'Bring Nature Indoors',
          summary:
              'Plants can brighten a space using very few resources.',
          details: [
            'Choose easy plants that suit the light in your home.',
            'Propagate cuttings to share with friends.',
            'Reuse old jars and tins as planters.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // PERSONAL CARE
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Personal Care',
      icon: Icons.spa_outlined,
      color: Color(0xFFB0568E),
      tips: [
        SustainabilityTip(
          title: 'Reusable and Refillable',
          summary:
              'Choose reusable or refillable personal-care products when possible.',
          details: [
            'Refill bottles of soap or shampoo instead of buying new ones.',
            'Consider safety razors or razors with replaceable heads.',
            'Use washable cotton rounds instead of disposable pads.',
          ],
        ),
        SustainabilityTip(
          title: 'Minimal, Recyclable Packaging',
          summary:
              'Look for products with minimal or recyclable packaging.',
          details: [
            'Solid bars often need much less packaging.',
            'Choose recyclable tubes and jars.',
            'Rinse containers before recycling them.',
          ],
        ),
        SustainabilityTip(
          title: 'Durable Over Single-Use',
          summary:
              'Choose durable alternatives to single-use personal-care items.',
          details: [
            'Pick toothbrushes with replaceable heads or bamboo handles.',
            'Use washable cloths instead of disposable wipes.',
            'Metal or wooden combs last far longer than cheap plastic ones.',
          ],
        ),
        SustainabilityTip(
          title: 'Use What You Have',
          summary: 'Finish products before buying new ones.',
          details: [
            'Use up half-empty bottles first.',
            'Avoid stockpiling products that may expire.',
            'Try samples before committing to a full-size product.',
          ],
        ),
        SustainabilityTip(
          title: 'Read the Ingredient List',
          summary:
              'Knowing what is inside helps you choose products that suit you and the planet.',
          details: [
            'Look for clear, complete ingredient lists.',
            'Recognised certifications can help you compare products.',
            'Patch-test new products if you have sensitive skin.',
          ],
        ),
        SustainabilityTip(
          title: 'Save Water While You Care',
          summary:
              'Simple habits cut water use in your daily routine.',
          details: [
            'Turn off the tap while brushing your teeth.',
            'Keep showers a little shorter.',
            'Fix dripping taps promptly.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // FASHION
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Fashion',
      icon: Icons.checkroom_outlined,
      color: Color(0xFF7B5EA7),
      tips: [
        SustainabilityTip(
          title: 'Buy for the Long Run',
          summary:
              'Choose durable clothing that can be worn for a long time.',
          details: [
            'Check seams, stitching, and fabric weight before buying.',
            'Pick timeless styles that will not feel dated quickly.',
            'Ask yourself whether you will wear it many times.',
          ],
        ),
        SustainabilityTip(
          title: 'Recycled and Responsible Materials',
          summary:
              'Consider recycled or responsibly sourced materials.',
          details: [
            'Options include recycled polyester, organic cotton, linen, and responsibly sourced wool.',
            'Read the material and care label.',
            'Look for recognised certifications rather than vague claims.',
          ],
        ),
        SustainabilityTip(
          title: 'Fewer, Better Items',
          summary:
              'Buy fewer, better-quality items that last longer.',
          details: [
            'Build a small core wardrobe of pieces that mix and match.',
            'Spend more on the items you wear most often.',
            'Skip impulse trend purchases.',
          ],
        ),
        SustainabilityTip(
          title: 'Care for Clothes to Extend Their Life',
          summary:
              'Good care can add years to your clothes.',
          details: [
            'Wash less often and follow the care label.',
            'Air-dry when possible.',
            'Mend small tears and replace missing buttons.',
          ],
        ),
        SustainabilityTip(
          title: 'Shop Second-Hand and Swap',
          summary:
              'Pre-loved clothing gives garments another life.',
          details: [
            'Try thrift stores and resale apps.',
            'Organise a clothes swap with friends.',
            'Donate or resell what you no longer wear.',
          ],
        ),
        SustainabilityTip(
          title: "Recycle What Can't Be Worn",
          summary:
              'Worn-out textiles can still be useful.',
          details: [
            'Turn old T-shirts into cleaning cloths.',
            'Use textile recycling drop-offs if available near you.',
            'Avoid sending textiles to general waste when alternatives exist.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // LAUNDRY
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Laundry',
      icon: Icons.local_laundry_service_outlined,
      color: Color(0xFF5A6ACF),
      tips: [
        SustainabilityTip(
          title: 'Wash Cold When You Can',
          summary:
              'Cold water handles most everyday loads and uses less energy than hot.',
          details: [
            'Check the care label first.',
            'Keep hot washes for heavily soiled items.',
            'Use a detergent that works well in cold water.',
          ],
        ),
        SustainabilityTip(
          title: 'Full Loads, Fewer Cycles',
          summary:
              'Running full loads uses water and energy more efficiently.',
          details: [
            'Wait until you have a full load.',
            'Choose the right load-size setting.',
            'Skip extra rinse cycles unless they are needed.',
          ],
        ),
        SustainabilityTip(
          title: 'Air-Dry Instead of Tumble',
          summary:
              'Drying on a line or rack uses no electricity.',
          details: [
            'Use a drying rack indoors.',
            'Sun-dry when the weather allows.',
            'Tumble dry only when you really need to.',
          ],
        ),
        SustainabilityTip(
          title: 'Use the Right Amount of Detergent',
          summary:
              'More detergent does not mean cleaner clothes.',
          details: [
            'Measure according to the label.',
            'Choose concentrated or refillable detergent.',
            'Pick products with recyclable packaging.',
          ],
        ),
        SustainabilityTip(
          title: 'Wear More, Wash Less',
          summary:
              'Not every item needs washing after a single wear.',
          details: [
            'Air out jeans, jackets, and sweaters between wears.',
            'Spot-clean small stains instead of washing the whole item.',
            'Washing less also helps clothes last longer.',
          ],
        ),
        SustainabilityTip(
          title: 'Catch Microfibres',
          summary:
              'Synthetic fabrics can shed tiny fibres in the wash.',
          details: [
            'Use a laundry bag or filter designed to catch microfibres.',
            'Wash synthetics less often and on gentle cycles.',
            'Prefer natural fibres for items you wash frequently.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // SHOPPING
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFC8553D),
      tips: [
        SustainabilityTip(
          title: 'Check Before You Buy',
          summary:
              'Ask whether you need it, and whether you already own something similar.',
          details: [
            'Wait a day before non-essential purchases.',
            'Borrow or rent items you will rarely use.',
            'Make a list before you go shopping.',
          ],
        ),
        SustainabilityTip(
          title: 'Read Labels Carefully',
          summary:
              'Labels reveal materials, certifications, and recycling information.',
          details: [
            'Look at the material composition.',
            'Recognised eco-certifications are more reliable than vague wording.',
            'Use the Eco Score in EcoWise to compare products quickly.',
          ],
        ),
        SustainabilityTip(
          title: 'Bring Your Own Bags',
          summary:
              'Reusable bags cut down on single-use plastic.',
          details: [
            'Keep a foldable bag in your everyday bag.',
            'Use small cloth bags for loose produce.',
            'Reuse your bags until they wear out.',
          ],
        ),
        SustainabilityTip(
          title: 'Choose Local When You Can',
          summary:
              'Local products often travel a shorter distance.',
          details: [
            'Shop at nearby stores and markets.',
            'Ask where products come from.',
            'Use the Stores tab to find eco-friendly shops near you.',
          ],
        ),
        SustainabilityTip(
          title: 'Beware of Greenwashing',
          summary:
              'Words like eco or natural do not guarantee a product is sustainable.',
          details: [
            'Look for specific claims you can verify.',
            'Check the actual material and packaging.',
            'Compare products using their Eco Score.',
          ],
        ),
        SustainabilityTip(
          title: 'Buy Quality, Not Quantity',
          summary:
              'One durable item usually beats several cheap ones.',
          details: [
            'Think about cost per use, not just the price tag.',
            'Read reviews for comments on durability.',
            'Check warranty and repair options.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // STORAGE
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Storage',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF7A6A58),
      tips: [
        SustainabilityTip(
          title: 'Reuse Before You Buy',
          summary:
              'Jars, tins, and boxes you already own make great storage.',
          details: [
            'Wash and repurpose glass jars.',
            'Reuse sturdy boxes for organising drawers and shelves.',
            'Label your containers so you use what you store.',
          ],
        ),
        SustainabilityTip(
          title: 'Choose Durable Containers',
          summary:
              'Sturdy containers outlast flimsy ones.',
          details: [
            'Glass and stainless steel can last for many years.',
            'Look for tight-fitting lids.',
            'Stackable shapes save space.',
          ],
        ),
        SustainabilityTip(
          title: 'Avoid Single-Use Bags and Wraps',
          summary:
              'Reusable options replace disposable storage items.',
          details: [
            'Try silicone or cloth storage bags.',
            'Use beeswax wraps for covering food.',
            'Keep a few lidded containers for leftovers.',
          ],
        ),
        SustainabilityTip(
          title: 'Store Food to Reduce Waste',
          summary:
              'Proper storage keeps food fresh for longer.',
          details: [
            'Store fruit and vegetables in the way that suits each type.',
            'Use airtight containers for dry goods.',
            'Move older items to the front so they get used first.',
          ],
        ),
        SustainabilityTip(
          title: 'Declutter Responsibly',
          summary:
              'Sort your items before you throw anything away.',
          details: [
            'Donate items that are still usable.',
            'Recycle materials where possible.',
            'Sell or swap things you no longer need.',
          ],
        ),
        SustainabilityTip(
          title: 'Right-Size Your Storage',
          summary:
              'Buying fewer, well-chosen containers avoids waste.',
          details: [
            'Measure the space before you buy.',
            'Choose a consistent set that stacks and fits together.',
            'Skip novelty storage you will not actually use.',
          ],
        ),
      ],
    ),

    // -----------------------------------------------------------------------
    // DINING
    // -----------------------------------------------------------------------
    SustainabilityCategory(
      name: 'Dining',
      icon: Icons.restaurant_outlined,
      color: Color(0xFF6B9A2E),
      tips: [
        SustainabilityTip(
          title: 'Bring Reusable Cutlery and Cups',
          summary:
              'Carry a small kit for takeaways and coffee.',
          details: [
            'Keep a cup, cutlery set, and straw in your bag.',
            'Say no to disposable extras.',
            'Many cafes are happy to fill your own cup.',
          ],
        ),
        SustainabilityTip(
          title: 'Order Only What You Will Finish',
          summary:
              'Reducing food waste matters as much as reducing packaging.',
          details: [
            'Share portions or ask for a smaller size.',
            'Take leftovers home in your own container.',
            'Plan meals so ingredients get used up.',
          ],
        ),
        SustainabilityTip(
          title: 'Choose Plant-Forward Meals',
          summary:
              'Eating more plants can lower your food footprint.',
          details: [
            'Try a meat-free meal a few days a week.',
            'Choose seasonal produce when possible.',
            'Explore local dishes built around vegetables and lentils.',
          ],
        ),
        SustainabilityTip(
          title: 'Skip the Extras',
          summary:
              'Say no to unnecessary napkins, sachets, and straws.',
          details: [
            'Decline items you will not use.',
            'Choose places that use less disposable packaging.',
            'Ask for no bag when you pick up an order.',
          ],
        ),
        SustainabilityTip(
          title: 'Support Sustainable Restaurants',
          summary:
              'Some restaurants source locally and work to reduce waste.',
          details: [
            'Look for local, seasonal menus.',
            'Ask about reusable or compostable serveware.',
            'Support places that donate surplus food.',
          ],
        ),
        SustainabilityTip(
          title: 'Host Low-Waste Meals',
          summary:
              'Small choices make gatherings greener.',
          details: [
            'Use real plates and cloth napkins.',
            'Cook the right amount for your guests.',
            'Compost food scraps if you can.',
          ],
        ),
      ],
    ),
  ];

  int get dayNumber {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(rotationStartDate).inDays;
  }

  List<SustainabilityTip> getTipsForCategory(
    SustainabilityCategory category,
  ) {
    final tips = category.tips;
    if (tips.isEmpty) return [];

    final offset = dayNumber % tips.length;

    return [
      ...tips.sublist(offset),
      ...tips.sublist(0, offset),
    ];
  }

  List<_TipWithCategory> get visibleTips {
    if (selectedCategory == 'All') {
      final result = <_TipWithCategory>[];

      for (final category in categories) {
        final rotatedTips = getTipsForCategory(category);

        // Show the first 3 tips from each category in "All".
        for (final tip in rotatedTips.take(3)) {
          result.add(
            _TipWithCategory(
              tip: tip,
              category: category,
            ),
          );
        }
      }

      return result;
    }

    final category = categories.firstWhere(
      (item) => item.name == selectedCategory,
    );

    return getTipsForCategory(category)
        .map(
          (tip) => _TipWithCategory(
            tip: tip,
            category: category,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6FBF5),
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Text(
              '🌱',
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(width: 8),
            Text(
              'Sustainability Tips',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF183D2A),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySelector(),
          const SizedBox(height: 18),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Recent Tips',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF173C29),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: visibleTips.length,
              itemBuilder: (context, index) {
                final item = visibleTips[index];

                return _TipCard(
                  tip: item.tip,
                  category: item.category,
                  onReadMore: () {
                    _showTipDetails(item.tip, item.category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categoryNames = [
      'All',
      ...categories.map((category) => category.name),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categoryNames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = categoryNames[index];
          final isSelected = selectedCategory == name;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = name;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3E9860)
                    : const Color(0xFFEFF7EE),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF3E9860)
                      : const Color(0xFFA7C5AE),
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF356B49),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTipDetails(
    SustainabilityTip tip,
    SustainabilityCategory category,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF173C29),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  tip.summary,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF4D5C53),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'What you can do',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173C29),
                  ),
                ),
                const SizedBox(height: 10),
                ...tip.details.map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '•',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xFF3E9860),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            detail,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: Color(0xFF4D5C53),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TipWithCategory {
  final SustainabilityTip tip;
  final SustainabilityCategory category;

  const _TipWithCategory({
    required this.tip,
    required this.category,
  });
}

class _TipCard extends StatelessWidget {
  final SustainabilityTip tip;
  final SustainabilityCategory category;
  final VoidCallback onReadMore;

  const _TipCard({
    required this.tip,
    required this.category,
    required this.onReadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: category.color.withOpacity(0.45),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              category.icon,
              color: category.color,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌱 ',
                      style: TextStyle(fontSize: 14),
                    ),
                    Expanded(
                      child: Text(
                        tip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F3D2C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  tip.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF59665E),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onReadMore,
                      child: const Text(
                        'Read More',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3E7F58),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: category.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
