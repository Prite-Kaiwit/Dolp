import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/nearby_products_map.dart';
import '../../widgets/product_image.dart';
import '../../utils/distance.dart';
import '../chat/chat_room_screen.dart';
import '../auth/login_screen.dart';
import '../order/cart_screen.dart';
import '../review_safety/report_screen.dart';
import '../profile/public_user_profile_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  final double? nearbyDistanceKm;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.nearbyDistanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final productDistance =
        nearbyDistanceKm ??
        distanceKm(appState.currentLocation, product.publicLocation);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดสินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('คัดลอกลิงก์ประกาศสินค้าเรียบร้อย'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppColors.error),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportScreen(
                    targetName: product.sellerName,
                    orderId: 'PROD-${product.id}',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Image
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.2,
                  child: PageView.builder(
                    itemCount: product.productImages.isEmpty
                        ? 1
                        : product.productImages.length,
                    itemBuilder: (context, index) =>
                        ProductImage.forProduct(product, index: index),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: ListingTypeBadge(
                    label: product.type.label,
                    isTrade: product.type == ListingType.trade,
                    isDonate: product.type == ListingType.donate,
                  ),
                ),
              ],
            ),

            // Main Info Container
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price and Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (product.type == ListingType.donate)
                        const Text(
                          'ส่งต่อฟรี (Free)',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.listingDonate,
                          ),
                        )
                      else if (product.type == ListingType.trade)
                        Text(
                          '฿${product.price.toStringAsFixed(0)} (รับแลก)',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.listingExchange,
                          ),
                        )
                      else
                        Text(
                          '฿${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.oceanBlue,
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grayBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.grayLine),
                        ),
                        child: Text(
                          product.condition,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.deepNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // No payment or transaction guarantees are implied.
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningPale,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.warning),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.shield_rounded,
                          color: AppColors.warning,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ซื้อขายอย่างระมัดระวัง',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ตกลงรายละเอียดและตรวจสอบสินค้าก่อนชำระเงิน',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Trade wishlist info if trade
                  if (product.type == ListingType.trade &&
                      product.tradeFor.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.listingExchangePale,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.listingExchange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                color: AppColors.listingExchange,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'สิ่งที่ต้องการแลกเปลี่ยน:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.listingExchange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.tradeFor,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Seller Info Card
                  const Text(
                    'ข้อมูลผู้ขาย',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.grayBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grayLine),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.aquaPale,
                          child: Text(
                            product.sellerName.isNotEmpty
                                ? product.sellerName[0]
                                : 'U',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.oceanBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            PublicUserProfileScreen(
                                              userId: product.sellerId,
                                            ),
                                      ),
                                    ),
                                    child: Text(
                                      product.sellerName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.deepNavy,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                ],
                              ),
                              Text(
                                product.sellerAreaLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.graySecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.aquaPale,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${product.sellerRating} (${product.sellerReviewCount} รีวิว)',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.deepNavy,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        color: AppColors.oceanBlue,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatDistance(productDistance),
                        style: const TextStyle(
                          color: AppColors.deepNavy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ตำแหน่งสินค้าโดยประมาณ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.locationLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.graySecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: PublicLocationPreview(
                      publicLocation: product.publicLocation,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'รูปแบบการนัดรับ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grayLine),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.aquaPale,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.oceanBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.pickupType.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.deepNavy,
                                ),
                              ),
                              const Text(
                                'ตำแหน่งในแผนที่เป็นจุดประมาณ ที่อยู่จริงต้องตกลงและแชร์ในแชท',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.graySecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'รายละเอียดเพิ่มเติม',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.deepNavy,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.deepNavy.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Chat with Seller Button
              if (appState.currentUser.id != product.sellerId) ...[
                OutlinedButton(
                  onPressed: () {
                    if (!appState.isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                      return;
                    }
                    final conversation = appState.openConversationForProduct(
                      product.id,
                    );
                    if (conversation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ไม่สามารถเริ่มบทสนทนานี้ได้'),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ChatRoomScreen(conversation: conversation),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    side: const BorderSide(color: AppColors.oceanBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 20,
                        color: AppColors.oceanBlue,
                      ),
                      Text(
                        'แชทกับผู้ขาย',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.oceanBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Add to cart button
              OutlinedButton(
                onPressed: () {
                  final error = appState.addToCart(product);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error)),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เพิ่ม "${product.title}" ลงตะกร้าแล้ว'),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: AppColors.grayLine),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_shopping_cart_rounded,
                      size: 20,
                      color: AppColors.deepNavy,
                    ),
                    Text(
                      'ใส่ตะกร้า',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.deepNavy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Local handoff flow; payment remains between the users.
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final error = appState.addToCart(product);
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product.type == ListingType.donate
                          ? AppColors.listingDonate
                          : AppColors.oceanBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      product.type == ListingType.donate
                          ? 'ขอนัดรับฟรี'
                          : product.type == ListingType.trade
                          ? 'ขอนัดแลกเปลี่ยน'
                          : 'ขอนัดซื้อ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
