import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../vendor/models/vendor_application_model.dart';
import '../models/store.dart';

SupabaseClient get _supabase => Supabase.instance.client;

enum VendorFilter { all, pending, approved, rejected }

class VendorFilterNotifier extends Notifier<VendorFilter> {
  @override
  VendorFilter build() => VendorFilter.all;

  void setFilter(VendorFilter filter) => state = filter;
}

final vendorFilterProvider =
    NotifierProvider.autoDispose<VendorFilterNotifier, VendorFilter>(
  VendorFilterNotifier.new,
);

final allVendorApplicationsProvider =
    FutureProvider.autoDispose<List<VendorApplication>>((ref) async {
  final filter = ref.watch(vendorFilterProvider);
  try {
    var query = _supabase.from('vendor_applications').select();

    switch (filter) {
      case VendorFilter.pending:
        query = query.eq('status', 'pending');
        break;
      case VendorFilter.approved:
        query = query.eq('status', 'approved');
        break;
      case VendorFilter.rejected:
        query = query.eq('status', 'rejected');
        break;
      case VendorFilter.all:
        break;
    }

    final rows = await query.order('created_at', ascending: false);
    final apps = (rows as List<dynamic>)
        .map((r) => VendorApplication.fromMap(r as Map<String, dynamic>))
        .toList();

    // Cross-check profiles to ensure any vendor account is visible in admin
    final existingUserIds = apps.map((a) => a.userId).toSet();
    var profileQuery = _supabase.from('profiles').select().eq('role', 'vendor');
    switch (filter) {
      case VendorFilter.pending:
        profileQuery = profileQuery.eq('vendor_status', 'pending');
        break;
      case VendorFilter.approved:
        profileQuery = profileQuery.eq('vendor_status', 'approved');
        break;
      case VendorFilter.rejected:
        profileQuery = profileQuery.eq('vendor_status', 'rejected');
        break;
      case VendorFilter.all:
        break;
    }

    final profileRows = await profileQuery;
    for (final p in (profileRows as List<dynamic>)) {
      final pMap = p as Map<String, dynamic>;
      final pId = pMap['id'] as String;
      if (!existingUserIds.contains(pId)) {
        Map<String, dynamic>? storeRow;
        try {
          final storeRows = await _supabase
              .from('stores')
              .select()
              .eq('vendor_id', pId)
              .order('created_at', ascending: false)
              .limit(1);
          final storeList = storeRows as List<dynamic>;
          if (storeList.isNotEmpty) {
            storeRow = storeList.first as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Store lookup skipped for vendor $pId: $e');
        }

        apps.add(VendorApplication(
          id: pId,
          userId: pId,
          ownerName: pMap['name'] as String? ?? 'Vendor Partner',
          email: pMap['email'] as String? ?? 'No email',
          contactNumber: pMap['contact_number'] as String? ?? 'Not provided',
          storeName: storeRow?['name'] as String? ?? '${pMap['name'] ?? 'Vendor'}\'s Store',
          storeAddress: storeRow?['address'] as String? ?? 'Address pending review',
          storeDescription: storeRow?['description'] as String?,
          storeCategory: storeRow?['category'] as String?,
          storeType: storeRow?['store_type'] as String? ?? 'physical',
          storeImageUrl: storeRow?['image_url'] as String?,
          status: pMap['vendor_status'] as String? ?? 'pending',
          createdAt: DateTime.tryParse(pMap['created_at'] as String? ?? '') ?? DateTime.now(),
          storeId: storeRow?['id'] as String?,
        ));
      }
    }

    return apps;
  } catch (e) {
    debugPrint('allVendorApplicationsProvider failed: $e');
    rethrow;
  }
});

final pendingVendorCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final apps = await ref.watch(allVendorApplicationsProvider.future);
    return apps.where((a) => a.status == 'pending').length;
  } catch (e) {
    return 0;
  }
});

/// Fetches stores where the vendor has requested store removal (awaiting Admin review).
final storeDeletionRequestsProvider = FutureProvider.autoDispose<List<Store>>((ref) async {
  final rows = await _supabase
      .from('stores')
      .select()
      .eq('deletion_requested', true)
      .order('deletion_requested_at', ascending: false);

  return (rows as List<dynamic>)
      .map((r) => Store.fromMap(r as Map<String, dynamic>))
      .toList();
});

class AdminVendorController {
  final Ref ref;
  AdminVendorController(this.ref);

  Future<void> approveVendor(VendorApplication app) async {
    final adminUser = _supabase.auth.currentUser;

    // Try RPC procedure first (runs with SECURITY DEFINER and bypasses RLS)
    try {
      await _supabase.rpc('admin_approve_vendor', params: {
        'target_user_id': app.userId,
        if (app.id != app.userId) 'target_app_id': app.id,
        if (app.storeId != null) 'target_store_id': app.storeId,
      });
      return;
    } catch (_) {}

    // Fallback: Direct table updates
    try {
      await _supabase.from('vendor_applications').update({
        'status': 'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminUser?.id,
      }).eq('id', app.id);
    } catch (_) {}

    // 2. Update profiles
    final updated = await _supabase.from('profiles').update({
      'role': 'vendor',
      'vendor_status': 'approved',
      'rejection_reason': null,
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': adminUser?.id,
    }).eq('id', app.userId).select('id');

    if ((updated as List).isEmpty) {
      throw Exception('Database update was blocked by Supabase RLS. Please run the SQL script in your Supabase SQL Editor.');
    }

    // 3. Activate associated store
    if (app.storeId != null) {
      await _supabase.from('stores').update({
        'is_approved': true,
      }).eq('id', app.storeId!);
    } else {
      // If storeId was null on application, approve stores with this vendor_id
      await _supabase.from('stores').update({
        'is_approved': true,
      }).eq('vendor_id', app.userId);
    }
  }

  Future<void> rejectVendor(VendorApplication app, String reason) async {
    final adminUser = _supabase.auth.currentUser;

    // Try RPC procedure first (runs with SECURITY DEFINER and bypasses RLS)
    try {
      await _supabase.rpc('admin_reject_vendor', params: {
        'target_user_id': app.userId,
        'reason': reason.trim(),
        if (app.id != app.userId) 'target_app_id': app.id,
        if (app.storeId != null) 'target_store_id': app.storeId,
      });
      return;
    } catch (_) {}

    // Fallback: Direct table updates
    try {
      await _supabase.from('vendor_applications').update({
        'status': 'rejected',
        'rejection_reason': reason.trim(),
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': adminUser?.id,
      }).eq('id', app.id);
    } catch (_) {}

    // 2. Update profiles with rejection status and reason
    final updated = await _supabase.from('profiles').update({
      'role': 'vendor',
      'vendor_status': 'rejected',
      'rejection_reason': reason.trim(),
      'reviewed_at': DateTime.now().toIso8601String(),
      'reviewed_by': adminUser?.id,
    }).eq('id', app.userId).select('id');

    if ((updated as List).isEmpty) {
      throw Exception('Database update was blocked by Supabase RLS. Please run the SQL script in your Supabase SQL Editor.');
    }

    // 3. Ensure store is marked not approved
    if (app.storeId != null) {
      await _supabase.from('stores').update({
        'is_approved': false,
      }).eq('id', app.storeId!);
    }
  }
}

final adminVendorControllerProvider = Provider<AdminVendorController>((ref) {
  return AdminVendorController(ref);
});
