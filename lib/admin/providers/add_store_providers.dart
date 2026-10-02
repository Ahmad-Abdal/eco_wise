import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store_model.dart';

class AddStoreState {
  final bool isSaving;
  final String? errorMessage;
  final bool isSaved;

  const AddStoreState({
    this.isSaving = false,
    this.errorMessage,
    this.isSaved = false,
  });

  AddStoreState copyWith({
    bool? isSaving,
    String? errorMessage,
    bool? isSaved,
  }) {
    return AddStoreState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class AddStoreNotifier extends Notifier<AddStoreState> {
  @override
  AddStoreState build() => const AddStoreState();

  SupabaseClient get supabase => Supabase.instance.client;

  Future<void> saveStore({
    required File imageFile,
    required String name,
    required String storeType,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? website,
    String? openingHours,
    String? description,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, isSaved: false);
    try {
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      await supabase.storage.from('store-images').upload(fileName, imageFile);
      final imageUrl = supabase.storage.from('store-images').getPublicUrl(fileName);

      final store = StoreModel(
        name: name,
        imageUrl: imageUrl,
        storeType: storeType,
        address: address,
        latitude: latitude,
        longitude: longitude,
        phone: phone,
        website: website,
        openingHours: openingHours,
        description: description,
      );

      await supabase.from('stores').insert(store.toMap());

      state = state.copyWith(isSaving: false, isSaved: true);
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  void reset() {
    state = const AddStoreState();
  }
}

final addStoreNotifierProvider = NotifierProvider<AddStoreNotifier, AddStoreState>(
  AddStoreNotifier.new,
);