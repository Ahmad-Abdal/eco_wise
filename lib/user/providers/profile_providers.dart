import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? city;
  final String? bio;
  final DateTime? createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.city,
    this.bio,
    this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] as String,
        name: map['name'] as String,
        email: map['email'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        city: map['city'] as String?,
        bio: map['bio'] as String?,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      );
}

/// All registered users — for the admin Users screen.
final allUsersProvider = FutureProvider.autoDispose<List<UserProfile>>((ref) async {
  final supabase = Supabase.instance.client;
  final data = await supabase.from('profiles').select().order('created_at', ascending: false);
  return (data as List).map((e) => UserProfile.fromMap(e)).toList();
});

/// Null → no profile row yet (first-time user, needs setup screen).
/// Non-null → returning user, skip straight to home.
final currentProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await supabase.from('profiles').select().eq('id', userId).maybeSingle();
  if (data == null) return null;
  return UserProfile.fromMap(data);
});

class ProfileSetupState {
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  const ProfileSetupState({
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  ProfileSetupState copyWith({bool? isSaving, bool? isSaved, String? errorMessage}) =>
      ProfileSetupState(
        isSaving: isSaving ?? this.isSaving,
        isSaved: isSaved ?? this.isSaved,
        errorMessage: errorMessage,
      );
}

class ProfileSetupNotifier extends Notifier<ProfileSetupState> {
  @override
  ProfileSetupState build() => const ProfileSetupState();

  SupabaseClient get supabase => Supabase.instance.client;

  Future<void> saveProfile({
    required String name,
    File? avatarFile,
    String? city,
    String? bio,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final userId = supabase.auth.currentUser?.id;
      final userEmail = supabase.auth.currentUser?.email;
      if (userId == null) throw Exception('No signed-in user');

      String? avatarUrl;
      if (avatarFile != null) {
        final fileExt = avatarFile.path.split('.').last;
        final fileName = '$userId.$fileExt';
        await supabase.storage.from('avatars').upload(
              fileName,
              avatarFile,
              fileOptions: const FileOptions(upsert: true),
            );
        avatarUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      }

     await supabase.from('profiles').upsert({
  'id': userId,
  'name': name,
  'email': userEmail,
  if (avatarUrl != null) 'avatar_url': avatarUrl,
  'city': city,
  'bio': bio,
  'profile_completed': true,  
});

      state = state.copyWith(isSaving: false, isSaved: true);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }
}

final profileSetupNotifierProvider =
    NotifierProvider.autoDispose<ProfileSetupNotifier, ProfileSetupState>(
  ProfileSetupNotifier.new,
);