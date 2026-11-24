class VendorApplication {
  final String id;
  final String userId;
  final String ownerName;
  final String email;
  final String contactNumber;
  final String storeName;
  final String storeAddress;
  final String? storeDescription;
  final String? storeCategory;
  final String storeType;
  final String? storeImageUrl;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? storeId;

  const VendorApplication({
    required this.id,
    required this.userId,
    required this.ownerName,
    required this.email,
    required this.contactNumber,
    required this.storeName,
    required this.storeAddress,
    this.storeDescription,
    this.storeCategory,
    this.storeType = 'physical',
    this.storeImageUrl,
    this.status = 'pending',
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.storeId,
  });

  factory VendorApplication.fromMap(Map<String, dynamic> map) {
    return VendorApplication(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      ownerName: map['owner_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      contactNumber: map['contact_number'] as String? ?? '',
      storeName: map['store_name'] as String? ?? '',
      storeAddress: map['store_address'] as String? ?? '',
      storeDescription: map['store_description'] as String?,
      storeCategory: map['store_category'] as String?,
      storeType: map['store_type'] as String? ?? 'physical',
      storeImageUrl: map['store_image_url'] as String?,
      status: map['status'] as String? ?? 'pending',
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      reviewedAt: map['reviewed_at'] != null ? DateTime.tryParse(map['reviewed_at'] as String) : null,
      reviewedBy: map['reviewed_by'] as String?,
      storeId: map['store_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'owner_name': ownerName,
      'email': email,
      'contact_number': contactNumber,
      'store_name': storeName,
      'store_address': storeAddress,
      'store_description': storeDescription,
      'store_category': storeCategory,
      'store_type': storeType,
      'store_image_url': storeImageUrl,
      'status': status,
      'rejection_reason': rejectionReason,
      'store_id': storeId,
    };
  }
}
