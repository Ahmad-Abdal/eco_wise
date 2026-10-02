class Store {
  final String id;
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
  final double? averageRating; // null until ratings exist
  final int ratingCount;
  final int productCount;

  const Store({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.storeType = 'physical',
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.website,
    this.openingHours,
    this.description,
    this.averageRating,
    this.ratingCount = 0,
    this.productCount = 0,
  });

  factory Store.fromMap(Map<String, dynamic> map) => Store(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        imageUrl: map['image_url'] as String? ?? '',
        storeType: map['store_type'] as String? ?? 'physical',
        address: map['address'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        phone: map['phone'] as String?,
        website: map['website'] as String?,
        openingHours: map['opening_hours'] as String?,
        description: map['description'] as String?,
        averageRating: (map['average_rating'] as num?)?.toDouble(),
        ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
        productCount: (map['product_count'] as num?)?.toInt() ?? 0,
      );
}