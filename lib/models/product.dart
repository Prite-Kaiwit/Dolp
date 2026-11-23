import 'geo_location.dart';
import 'product_image_data.dart';
import '../utils/json_helpers.dart';

enum ListingType { sell, trade, donate }

enum PickupType { sellerHome, agreedSpot, suggestedSpot, discussInChat }

extension PickupTypeExtension on PickupType {
  String get label {
    switch (this) {
      case PickupType.sellerHome:
        return 'บ้านผู้ขาย';
      case PickupType.agreedSpot:
        return 'จุดที่ตกลงกัน';
      case PickupType.suggestedSpot:
        return 'จุดแนะนำสาธารณะ';
      case PickupType.discussInChat:
        return 'ตกลงกันในแชท';
    }
  }
}

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

enum ListingStatus { active, reserved, sold, hidden }

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
  final String imageUrl;
  final List<String> images;
  final List<ProductImageData> productImages;
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
    required this.imageUrl,
    this.images = const [],
    this.productImages = const [],
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

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'tradeFor': tradeFor,
    'type': type.name,
    'category': category,
    'condition': condition,
    'publicLocation': publicLocation.toJson(),
    'locationLabel': locationLabel,
    'pickupType': pickupType.name,
    'imageUrl': imageUrl,
    'images': images,
    'productImages': productImages.map((image) => image.toJson()).toList(),
    'sellerId': sellerId,
    'sellerName': sellerName,
    'sellerAreaLabel': sellerAreaLabel,
    'sellerRating': sellerRating,
    'sellerReviewCount': sellerReviewCount,
    'status': status.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'viewCount': viewCount,
    'favoriteCount': favoriteCount,
  };

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: jsonString(json['id'], 'missing-product'),
    title: jsonString(json['title'], 'ประกาศสินค้า'),
    description: jsonString(json['description']),
    price: jsonDouble(json['price']),
    tradeFor: jsonString(json['tradeFor']),
    type: jsonEnum(ListingType.values, json['type'], ListingType.sell),
    category: jsonString(json['category'], 'อื่น ๆ'),
    condition: jsonString(json['condition'], 'ไม่ระบุ'),
    publicLocation: GeoLocation.fromJson(jsonObject(json['publicLocation'])),
    locationLabel: jsonString(json['locationLabel']),
    pickupType: jsonEnum(
      PickupType.values,
      json['pickupType'],
      PickupType.discussInChat,
    ),
    imageUrl: jsonString(json['imageUrl']),
    images: jsonList(json['images']).whereType<String>().toList(),
    productImages: jsonList(
      json['productImages'],
    ).map((image) => ProductImageData.fromJson(jsonObject(image))).toList(),
    sellerId: jsonString(json['sellerId']),
    sellerName: jsonString(json['sellerName'], 'ผู้ขาย'),
    sellerAreaLabel: jsonString(json['sellerAreaLabel']),
    sellerRating: jsonDouble(json['sellerRating']),
    sellerReviewCount: jsonInt(json['sellerReviewCount']),
    status: jsonEnum(
      ListingStatus.values,
      json['status'],
      ListingStatus.active,
    ),
    createdAt: jsonDateTime(json['createdAt']),
    viewCount: jsonInt(json['viewCount']),
    favoriteCount: jsonInt(json['favoriteCount']),
  );

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
    String? imageUrl,
    List<String>? images,
    List<ProductImageData>? productImages,
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
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      productImages: productImages ?? this.productImages,
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

  ProductImageData? get coverImage {
    if (productImages.isNotEmpty) return productImages.first;
    if (imageUrl.isNotEmpty) return ProductImageData.network(imageUrl);
    return null;
  }
}
