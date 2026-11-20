import 'product.dart';

enum SortBy { nearest, newest, priceAsc, priceDesc }

class NearbyProduct {
  final ProductModel product;
  final double distanceKm;

  const NearbyProduct({required this.product, required this.distanceKm});
}
