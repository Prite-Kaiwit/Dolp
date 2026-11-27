import 'user.dart';

enum SellerKind { all, shops, people }

class NearbyShop {
  final UserModel shop;
  final double distanceKm;
  final bool isOpenNow;
  final int matchingListingCount;

  const NearbyShop({
    required this.shop,
    required this.distanceKm,
    required this.isOpenNow,
    required this.matchingListingCount,
  });
}
