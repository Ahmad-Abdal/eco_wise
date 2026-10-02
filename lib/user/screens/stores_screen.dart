import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/nearby_stores_providers.dart';
import '../../core/config/env_config.dart';
import 'user_store_detail_screen.dart';
import 'web_view_screen.dart';

class StoresScreen extends ConsumerStatefulWidget {
  const StoresScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StoresScreen> createState() => StoresScreenState();
}

class StoresScreenState extends ConsumerState<StoresScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF6B6B6B);
  static const Color primaryGreen = Color(0xFF1B7A43);
  static const Color lightGreenBg = Color(0xFFE7F4EC);
  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color sectionFill = Color(0xFFF7F8F6);

  bool showMapView = false;
  final mapController = MapController();

  bool isPhysicalWithCoords(dynamic store) {
    return store.storeType == 'physical' && store.latitude != null && store.longitude != null;
  }

  Future<void> openDirections(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void openWebsite(String website, String storeName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WebViewScreen(url: website, title: storeName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(nearbyStoresProvider);
    final positionAsync = ref.watch(userPositionProvider);

    return Container(
      color: pureWhite,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.location_on_rounded, color: primaryGreen, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Nearby Stores', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: sectionFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderGray),
              ),
              child: Row(
                children: [
                  Expanded(child: _toggleButton('Map View', showMapView, () => setState(() => showMapView = true))),
                  Expanded(child: _toggleButton('List View', !showMapView, () => setState(() => showMapView = false))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: storesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: primaryGreen)),
              error: (e, s) => Center(child: Text('Could not load stores.\n$e', textAlign: TextAlign.center, style: const TextStyle(color: textDark))),
              data: (stores) {
                if (stores.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: sectionFill),
                          child: Icon(Icons.storefront_outlined, color: textGray.withOpacity(0.5), size: 30),
                        ),
                        const SizedBox(height: 12),
                        Text('No stores yet.', style: TextStyle(color: textGray.withOpacity(0.8))),
                      ],
                    ),
                  );
                }
                return showMapView
                    ? _buildMapView(stores, positionAsync.value)
                    : _buildListView(stores);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected ? [BoxShadow(color: primaryGreen.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : textGray,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<NearbyStore> stores) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final ns = stores[index];
        final store = ns.store;
        final isPhysical = store.storeType == 'physical';
        final hasCoordinates = store.latitude != null && store.longitude != null;
        final hasWebsite = store.website != null && store.website!.trim().isNotEmpty;
        final directionsEnabled = isPhysical && hasCoordinates;
        final websiteEnabled = !isPhysical && hasWebsite;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: pureWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderGray),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      store.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 64,
                        height: 64,
                        color: sectionFill,
                        child: const Icon(Icons.storefront_rounded, color: textGray),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (store.averageRating != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFFFFF6E0), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF2B705)),
                                    const SizedBox(width: 2),
                                    Text(store.averageRating!.toStringAsFixed(1),
                                        style: const TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ] else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: sectionFill, borderRadius: BorderRadius.circular(8)),
                                child: Text('New', style: TextStyle(color: textGray.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            if (isPhysical && ns.distanceKm != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.near_me_outlined, size: 13, color: textGray.withOpacity(0.7)),
                              const SizedBox(width: 3),
                              Text('${ns.distanceKm!.toStringAsFixed(1)} km away',
                                  style: TextStyle(color: textGray.withOpacity(0.85), fontSize: 12)),
                            ] else if (!isPhysical) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.language_rounded, size: 13, color: textGray.withOpacity(0.7)),
                              const SizedBox(width: 3),
                              Text('Online', style: TextStyle(color: textGray.withOpacity(0.85), fontSize: 12)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: directionsEnabled || websiteEnabled ? primaryGreen : borderGray,
                          width: 1.3,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: isPhysical
                          ? (directionsEnabled ? () => openDirections(store.latitude!, store.longitude!) : null)
                          : (websiteEnabled ? () => openWebsite(store.website!, store.name) : null),
                      icon: Icon(
                        isPhysical ? Icons.directions_rounded : Icons.language_rounded,
                        size: 18,
                        color: directionsEnabled || websiteEnabled ? primaryGreen : textGray,
                      ),
                      label: Text(
                        isPhysical ? 'Directions' : 'Visit Website',
                        style: TextStyle(
                          color: directionsEnabled || websiteEnabled ? primaryGreen : textGray,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserStoreDetailScreen(storeId: store.id)),
                        ).then((_) => ref.invalidate(nearbyStoresProvider));
                      },
                      child: const Text('View Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView(List<NearbyStore> stores, dynamic position) {
    // Only physical stores with real coordinates get a pin. An online
    // store has no location at all, so it's excluded here rather than
    // ever falling back to a placeholder point like (0,0).
    final mappableStores = stores.where((ns) => isPhysicalWithCoords(ns.store)).toList();

    final center = position != null
        ? LatLng(position.latitude, position.longitude)
        : (mappableStores.isNotEmpty
            // Safe: isPhysicalWithCoords already guarantees these are
            // non-null for everything in mappableStores — the ! just
            // tells the analyzer what we already filtered for.
            ? LatLng(mappableStores.first.store.latitude!, mappableStores.first.store.longitude!)
            : const LatLng(24.8607, 67.0011));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(initialCenter: center, initialZoom: 13),
        children: [
          TileLayer(
            urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${EnvConfig.mapTilerApiKey}',
            userAgentPackageName: 'com.ecowise.app',
          ),
          MarkerLayer(
            markers: [
              if (position != null)
                Marker(
                  point: LatLng(position.latitude, position.longitude),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.my_location_rounded, color: Colors.blue, size: 32),
                ),
              for (final ns in mappableStores)
                Marker(
                  // Safe for the same reason as above — mappableStores
                  // is already filtered to physical stores with coords.
                  point: LatLng(ns.store.latitude!, ns.store.longitude!),
                  width: 46,
                  height: 46,
                  child: GestureDetector(
                    onTap: () => _showStoreSheet(ns),
                    child: const Icon(Icons.location_pin, color: primaryGreen, size: 44),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStoreSheet(NearbyStore ns) {
    // Only ever called from a map marker, which only exists for
    // physical stores with real coordinates — no online-store branch
    // needed here.
    final store = ns.store;
    showModalBottomSheet(
      context: context,
      backgroundColor: pureWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: borderGray, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: lightGreenBg, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.storefront_rounded, color: primaryGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textDark)),
                        const SizedBox(height: 2),
                        Text(store.address ?? 'Address not available', style: TextStyle(color: textGray.withOpacity(0.85), fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (store.averageRating != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFFFFF6E0), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF2B705), size: 16),
                          const SizedBox(width: 4),
                          Text(store.averageRating!.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                  if (ns.distanceKm != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.near_me_outlined, size: 14, color: textGray.withOpacity(0.7)),
                    const SizedBox(width: 3),
                    Text('${ns.distanceKm!.toStringAsFixed(1)} km away', style: TextStyle(color: textGray.withOpacity(0.85), fontSize: 12.5)),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    openDirections(store.latitude!, store.longitude!);
                  },
                  icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 20),
                  label: const Text('Get Directions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}