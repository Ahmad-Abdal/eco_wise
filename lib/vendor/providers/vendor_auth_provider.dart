import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorRegistrationData {
  final String ownerName;
  final String email;
  final String password;
  final String contactNumber;
  final String storeName;
  final String storeType;
  final String storeAddress;
  final double? latitude;
  final double? longitude;
  final String storeCategory;
  final String? storeDescription;
  final File storeImageFile;

  const VendorRegistrationData({
    required this.ownerName,
    required this.email,
    required this.password,
    required this.contactNumber,
    required this.storeName,
    required this.storeType,
    required this.storeAddress,
    this.latitude,
    this.longitude,
    required this.storeCategory,
    this.storeDescription,
    required this.storeImageFile,
  });
}

class VendorAuthState {
  final bool isLoading;
  final String? errorMessage;
  final bool isRegistered;
  final String? vendorStatus; // 'none' | 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;

  const VendorAuthState({
    this.isLoading = false,
    this.errorMessage,
    this.isRegistered = false,
    this.vendorStatus,
    this.rejectionReason,
  });

  VendorAuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isRegistered,
    String? vendorStatus,
    String? rejectionReason,
  }) {
    return VendorAuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isRegistered: isRegistered ?? this.isRegistered,
      vendorStatus: vendorStatus ?? this.vendorStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}

class VendorAuthNotifier extends Notifier<VendorAuthState> {
  @override
  VendorAuthState build() => const VendorAuthState();

  SupabaseClient get supabase => Supabase.instance.client;

  Future<bool> registerVendor(VendorRegistrationData data) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isRegistered: false);
    try {
      User? user;

      // 1. Attempt user sign up in Supabase Auth
      try {
        final authResponse = await supabase.auth.signUp(
          email: data.email.trim(),
          password: data.password,
          data: {
            'name': data.ownerName.trim(),
            'role': 'vendor',
            'contact_number': data.contactNumber.trim(),
          },
        );
        user = authResponse.user;
      } on AuthException catch (signUpErr) {
        if (signUpErr.message.toLowerCase().contains('already registered') ||
            signUpErr.statusCode == '422' ||
            signUpErr.code == 'user_already_exists') {
          // If the email is already registered, authenticate with the provided password
          // so this user can apply for/upgrade to a vendor partner account.
          try {
            final signInRes = await supabase.auth.signInWithPassword(
              email: data.email.trim(),
              password: data.password,
            );
            user = signInRes.user;
          } catch (_) {
            throw const AuthException(
              'An account with this email already exists. Please enter your existing account password to submit your vendor application, or sign in.',
            );
          }
        } else {
          rethrow;
        }
      }

      if (user == null) {
        throw Exception('User registration failed: No user returned');
      }

      // Ensure active session for storage uploads and table operations
      if (supabase.auth.currentSession == null) {
        try {
          await supabase.auth.signInWithPassword(
            email: data.email.trim(),
            password: data.password,
          );
        } catch (_) {}
      }

      // Check if user already submitted a pending or approved vendor application
      final existingAppRows = await supabase
          .from('vendor_applications')
          .select('id, status, rejection_reason')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1);
      final existingAppList = existingAppRows as List<dynamic>;
      final existingApp = existingAppList.isNotEmpty
          ? existingAppList.first as Map<String, dynamic>
          : null;

      if (existingApp != null) {
        final status = existingApp['status'] as String? ?? 'pending';
        if (status == 'pending') {
          state = state.copyWith(
            isLoading: false,
            isRegistered: true,
            vendorStatus: 'pending',
          );
          return true;
        } else if (status == 'approved') {
          throw const AuthException('Your vendor account is already approved! Please sign in to access your vendor dashboard.');
        }
      }

      // 2. Upload store image to store-images bucket with fallback
      String imageUrl = 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800';
      try {
        final ext = data.storeImageFile.path.split('.').last;
        final fileName = 'vendor_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        await supabase.storage.from('store-images').upload(
              fileName,
              data.storeImageFile,
              fileOptions: const FileOptions(upsert: true),
            );
        imageUrl = supabase.storage.from('store-images').getPublicUrl(fileName);
      } catch (_) {
        // Fallback placeholder image ensures registration completes
      }

      // 3. Upsert profile with vendor role & pending status
      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': data.ownerName.trim(),
        'email': data.email.trim(),
        'role': 'vendor',
        'vendor_status': 'pending',
        'contact_number': data.contactNumber.trim(),
        'profile_completed': true,
        'onboarding_completed': true,
      });

      // 4. Create the store record marked as not approved yet
      final storeRow = await supabase.from('stores').insert({
        'name': data.storeName.trim(),
        'image_url': imageUrl,
        'store_type': data.storeType,
        'address': data.storeAddress.trim(),
        'latitude': data.latitude,
        'longitude': data.longitude,
        'phone': data.contactNumber.trim(),
        'description': data.storeDescription?.trim(),
        'category': data.storeCategory,
        'vendor_id': user.id,
        'is_approved': false,
      }).select().single();

      final storeId = storeRow['id'] as String;

      // 5. Create the vendor application record for Admin review
      await supabase.from('vendor_applications').insert({
        'user_id': user.id,
        'owner_name': data.ownerName.trim(),
        'email': data.email.trim(),
        'contact_number': data.contactNumber.trim(),
        'store_name': data.storeName.trim(),
        'store_address': data.storeAddress.trim(),
        'store_description': data.storeDescription?.trim(),
        'store_category': data.storeCategory,
        'store_type': data.storeType,
        'store_image_url': imageUrl,
        'status': 'pending',
        'store_id': storeId,
      });

      state = state.copyWith(
        isLoading: false,
        isRegistered: true,
        vendorStatus: 'pending',
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isRegistered: false,
      );
      return false;
    } on PostgrestException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        isRegistered: false,
      );
      return false;
    } on StorageException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Storage error: ${e.message}',
        isRegistered: false,
      );
      return false;
    } catch (error) {
      final errStr = error.toString();
      String cleanMsg = errStr;
      if (errStr.contains('SocketException') ||
          errStr.contains('Connection reset') ||
          errStr.contains('AuthRetryableFetchException') ||
          errStr.contains('ClientException')) {
        cleanMsg = 'Connection error: Connection dropped. Please check your internet connection and try again.';
      } else if (errStr.contains('AuthApiException')) {
        final match = RegExp(r'message:\s*([^,)]+)').firstMatch(errStr);
        cleanMsg = match != null ? match.group(1)!.trim() : 'Authentication error';
      } else {
        cleanMsg = cleanMsg.replaceFirst(RegExp(r'^Exception:\s*'), '');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: cleanMsg,
        isRegistered: false,
      );
      return false;
    }
  }

  Future<void> checkCurrentVendorStatus() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      state = const VendorAuthState();
      return;
    }

    try {
      final profile = await supabase
          .from('profiles')
          .select('role, vendor_status, rejection_reason')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        state = state.copyWith(
          vendorStatus: profile['vendor_status'] as String? ?? 'none',
          rejectionReason: profile['rejection_reason'] as String?,
        );
      }
    } catch (e) {
      // Keep existing state on transient error
    }
  }

  void reset() {
    state = const VendorAuthState();
  }
}

final vendorAuthNotifierProvider =
    NotifierProvider<VendorAuthNotifier, VendorAuthState>(
  VendorAuthNotifier.new,
);
