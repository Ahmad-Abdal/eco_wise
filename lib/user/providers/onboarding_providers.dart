import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_providers.dart';

const pricePreferenceOptions = ['Budget', 'Moderate', 'Premium'];

class OnboardingState {
  final Set<String> selectedCategories;
  final String? pricePreference;
  final bool isSaving;
  final String? errorMessage;

  const OnboardingState({
    this.selectedCategories = const {},
    this.pricePreference,
    this.isSaving = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    Set<String>? selectedCategories,
    String? pricePreference,
    bool? isSaving,
    String? errorMessage,
  }) {
    return OnboardingState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      pricePreference: pricePreference ?? this.pricePreference,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  SupabaseClient get supabase => Supabase.instance.client;

  void toggleCategory(String category) {
    final updated = Set<String>.from(state.selectedCategories);
    if (!updated.remove(category)) updated.add(category);
    state = state.copyWith(selectedCategories: updated);
  }

  void setPricePreference(String value) {
    state = state.copyWith(pricePreference: value);
  }

  Future<bool> savePreferences() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(isSaving: false, errorMessage: 'No signed-in user');
      return false;
    }
    try {
      await supabase.from('profiles').update({
        'preferred_categories': state.selectedCategories.toList(),
        'price_preference': state.pricePreference,
        'onboarding_completed': true,
      }).eq('id', userId);
      state = state.copyWith(isSaving: false);
      // Home screen must re-fetch with the new preferences.
      ref.invalidate(recommendedProductsProvider);
      return true;
    } catch (error) {
      debugPrint('savePreferences failed: $error');
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
      return false;
    }
  }

  Future<bool> skipOnboarding() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(isSaving: false, errorMessage: 'No signed-in user');
      return false;
    }
    try {
      await supabase.from('profiles').update({
        'onboarding_completed': true,
      }).eq('id', userId);
      state = state.copyWith(isSaving: false);
      ref.invalidate(recommendedProductsProvider);
      return true;
    } catch (error) {
      debugPrint('skipOnboarding failed: $error');
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
      return false;
    }
  }
}

final onboardingNotifierProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);