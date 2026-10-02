import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../admin/models/store.dart';

class NearbyStore {
  final Store store;
  final double? distanceKm; // null if location unavailable

  const NearbyStore({required this.store, this.distanceKm});
}

/// Gets the user's current position. Returns null (rather than throwing)
/// if permission is denied or location services are off — the UI then
/// falls back to showing stores unsorted, no distance.
final userPositionProvider = FutureProvider.autoDispose<Position?>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  } catch (_) {
    return null;
  }
});

final nearbyStoresProvider = FutureProvider.autoDispose<List<NearbyStore>>((ref) async {
  final supabase = Supabase.instance.client;
  final position = await ref.watch(userPositionProvider.future);

  final data = await supabase.from('store_summary').select();
  final stores = (data as List).map((e) => Store.fromMap(e)).toList();

  final nearby = stores.map((store) {
    double? distanceKm;
    if (position != null) {
      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        store.latitude ?? 0.0,
        store.longitude ?? 0.0,
      );
      distanceKm = meters / 1000;
    }
    return NearbyStore(store: store, distanceKm: distanceKm);
  }).toList();

  if (position != null) {
    nearby.sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
  }

  return nearby;
});