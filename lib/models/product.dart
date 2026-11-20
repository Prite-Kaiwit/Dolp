// The legacy pickupPoint field remains until listing and order screens migrate.
// ignore_for_file: deprecated_member_use

import 'geo_location.dart';

enum ListingType { sell, trade, donate }

enum PickupType { sellerHome, agreedSpot, suggestedSpot, discussInChat }

extension ListingTypeExtension on ListingType {
  String get label {
    switch (this) {
      case ListingType.sell:
        return 'ขาย';
      case ListingType.trade:
        return 'แลกเปลี่ยน';
      case ListingType.donate:
        return 'บริจาค/ฟรี';
    }
  }
}

enum ListingStatus { active, sold, hidden }

class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price; // 0 for donate
  final String tradeFor; // What seller wants to trade for
  final ListingType type;
  final String category;
  final String condition;
  final GeoLocation publicLocation;
  final String locationLabel;
  final PickupType pickupType;
  @Deprecated('Use locationLabel and pickupType; remove after phase 6.')
  final String pickupPoint;
  final String imageUrl;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final String sellerAreaLabel;
  final double sellerRating;
  final int sellerReviewCount;
  final ListingStatus status;
  final DateTime createdAt;
  final int viewCount;
  final int favoriteCount;

  ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.tradeFor = '',
    required this.type,
    required this.category,
    required this.condition,
    required this.publicLocation,
    this.locationLabel = '',
    this.pickupType = PickupType.discussInChat,
    required this.pickupPoint,
    required this.imageUrl,
    this.images = const [],
    required this.sellerId,
    required this.sellerName,
    required this.sellerAreaLabel,
    this.sellerRating = 4.8,
    this.sellerReviewCount = 12,
    this.status = ListingStatus.active,
    DateTime? createdAt,
    this.viewCount = 45,
    this.favoriteCount = 6,
  }) : createdAt = createdAt ?? DateTime.now();

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? tradeFor,
    ListingType? type,
    String? category,
    String? condition,
    GeoLocation? publicLocation,
    String? locationLabel,
    PickupType? pickupType,
    String? pickupPoint,
    String? imageUrl,
    List<String>? images,
    String? sellerId,
    String? sellerName,
    String? sellerAreaLabel,
    double? sellerRating,
    int? sellerReviewCount,
    ListingStatus? status,
    DateTime? createdAt,
    int? viewCount,
    int? favoriteCount,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      tradeFor: tradeFor ?? this.tradeFor,
      type: type ?? this.type,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      publicLocation: publicLocation ?? this.publicLocation,
      locationLabel: locationLabel ?? this.locationLabel,
      pickupType: pickupType ?? this.pickupType,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAreaLabel: sellerAreaLabel ?? this.sellerAreaLabel,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerReviewCount: sellerReviewCount ?? this.sellerReviewCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
    );
  }
}
