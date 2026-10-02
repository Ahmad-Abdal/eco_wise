class StoreModel {
  final String name;
  final String imageUrl;
  final String storeType; // 'physical' or 'online'
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? website;
  final String? openingHours;
  final String? description;

  const StoreModel({
    required this.name,
    required this.imageUrl,
    required this.storeType,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.website,
    this.openingHours,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image_url': imageUrl,
      'store_type': storeType,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'website': website,
      'opening_hours': openingHours,
      'description': description,
    };
  }
}