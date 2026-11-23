import 'product.dart';
import '../utils/json_helpers.dart';

enum SortBy { nearest, newest, priceAsc, priceDesc }

class NearbyProduct {
  final ProductModel product;
  final double distanceKm;

  const NearbyProduct({required this.product, required this.distanceKm});

  Map<String, Object> toJson() => {
    'product': product.toJson(),
    'distanceKm': distanceKm,
  };

  factory NearbyProduct.fromJson(Map<String, dynamic> json) => NearbyProduct(
    product: ProductModel.fromJson(jsonObject(json['product'])),
    distanceKm: jsonDouble(json['distanceKm']),
  );
}
