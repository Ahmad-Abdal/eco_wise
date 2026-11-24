import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../admin/models/store.dart';
import '../providers/admin_vendor_providers.dart';
import '../providers/dashboard_providers.dart';
import '../providers/store_list_providers.dart';
import 'admin_vendor_detail_screen.dart';
import 'store_detail_screen.dart';

class AdminVendorRequestsScreen extends ConsumerWidget {
  const AdminVendorRequestsScreen({Key? key}) : super(key: key);

  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  String formatShortDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(allVendorApplicationsProvider);
    ref.invalidate(storeDeletionRequestsProvider);
    ref.invalidate(storeListProvider);
    ref.invalidate(pendingVendorCountProvider);
    ref.invalidate(dashboardStatsProvider);
  }

  Widget _buildStoreDeletionSection(
    BuildContext context,
    WidgetRef ref,
    List<Store> deletionStores,
  ) {
    if (deletionStores.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCCCC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Store Removal Requests (${deletionStores.length})',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...deletionStores.map((store) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StoreDetailScreen(storeId: store.id)),
                ).then((_) => _refreshAll(ref));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD6D6)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        store.imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: sectionFill,
                          child: const Icon(Icons.storefront_rounded, color: Colors.redAccent, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reason: "${store.deletionReason ?? 'No reason provided'}"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: textGray, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    VendorFilter filter,
    VendorFilter currentFilter,
  ) {
    final isSelected = currentFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      selectedColor: lightGreenBg,
      backgroundColor: sectionFill,
      labelStyle: TextStyle(
        color: isSelected ? primaryGreen : textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(color: isSelected ? primaryGreen : borderGray),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) {
        ref.read(vendorFilterProvider.notifier).setFilter(filter);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(vendorFilterProvider);
    final applicationsAsync = ref.watch(allVendorApplicationsProvider);
    final deletionRequestsAsync = ref.watch(storeDeletionRequestsProvider);
    final deletionStores = deletionRequestsAsync.maybeWhen(
      data: (v) => v,
      orElse: () => const <Store>[],
    );

    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text(
          'Vendor Management',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textDark),
            tooltip: 'Refresh from database',
            onPressed: () => _refreshAll(ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  buildFilterChip(context, ref, 'All', VendorFilter.all, currentFilter),
                  const SizedBox(width: 8),
                  buildFilterChip(context, ref, 'Pending', VendorFilter.pending, currentFilter),
                  const SizedBox(width: 8),
                  buildFilterChip(context, ref, 'Approved', VendorFilter.approved, currentFilter),
                  const SizedBox(width: 8),
                  buildFilterChip(context, ref, 'Rejected', VendorFilter.rejected, currentFilter),
                ],
              ),
            ),
            const Divider(height: 1, color: borderGray),

            // Applications & Store Deletion Requests List
            Expanded(
              child: RefreshIndicator(
                color: primaryGreen,
                onRefresh: () async => _refreshAll(ref),
                child: applicationsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
                  error: (error, _) => ListView(
                    children: [
                      _buildStoreDeletionSection(context, ref, deletionStores),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not load vendor applications.\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: textDark),
                        ),
                      ),
                    ],
                  ),
                  data: (apps) {
                    if (apps.isEmpty) {
                      return ListView(
                        children: [
                          _buildStoreDeletionSection(context, ref, deletionStores),
                          const SizedBox(height: 80),
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: lightGreenBg,
                              ),
                              child: const Icon(Icons.storefront_rounded, size: 38, color: primaryGreen),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'No applications found',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Vendor applications will appear here for review.',
                              style: TextStyle(color: textGray, fontSize: 13),
                            ),
                          ),
                        ],
                      );
                    }

                    final hasDeletions = deletionStores.isNotEmpty;
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: apps.length + (hasDeletions ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (hasDeletions && index == 0) {
                          return _buildStoreDeletionSection(context, ref, deletionStores);
                        }
                        final app = apps[hasDeletions ? index - 1 : index];

                        Color statusColor;
                        Color statusBg;
                        switch (app.status) {
                          case 'approved':
                            statusColor = primaryGreen;
                            statusBg = lightGreenBg;
                            break;
                          case 'rejected':
                            statusColor = Colors.redAccent;
                            statusBg = const Color(0xFFFFEBEE);
                            break;
                          default:
                            statusColor = const Color(0xFFE67E22);
                            statusBg = const Color(0xFFFFF4E5);
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminVendorDetailScreen(application: app),
                              ),
                            ).then((_) => _refreshAll(ref));
                          },
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: pureWhite,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderGray),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: app.storeImageUrl != null
                                          ? Image.network(
                                              app.storeImageUrl!,
                                              width: 44,
                                              height: 44,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 44,
                                                height: 44,
                                                color: sectionFill,
                                                child: const Icon(Icons.storefront, color: primaryGreen),
                                              ),
                                            )
                                          : Container(
                                              width: 44,
                                              height: 44,
                                              color: sectionFill,
                                              child: const Icon(Icons.storefront, color: primaryGreen),
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            app.storeName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Owner: ${app.ownerName}',
                                            style: const TextStyle(color: textGray, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        app.status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 14, color: textGray),
                                        const SizedBox(width: 4),
                                        Text(app.contactNumber, style: const TextStyle(fontSize: 12, color: textGray)),
                                      ],
                                    ),
                                    Text(
                                      formatShortDate(app.createdAt),
                                      style: const TextStyle(fontSize: 12, color: textGray),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
