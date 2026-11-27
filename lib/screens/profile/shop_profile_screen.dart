import 'package:flutter/material.dart';

import '../../models/nearby_product.dart';
import '../../models/product.dart';
import '../../models/shop_profile.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../utils/thai_time.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shop_badge.dart';
import '../auth/login_screen.dart';
import '../chat/chat_room_screen.dart';
import '../home/product_detail_screen.dart';
import '../review_safety/report_screen.dart';

const String kDefaultShopInquiryDraft = 'สวัสดีครับ สอบถามสินค้าหน่อยครับ';

/// Starts (or reopens) an inquiry chat with a shop. Guests are sent to login.
void startShopInquiry(
  BuildContext context,
  AppState appState,
  String shopUserId, {
  String? draft,
}) {
  if (!appState.isLoggedIn) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
    return;
  }
  final conversation = appState.openShopInquiry(shopUserId);
  if (conversation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ไม่สามารถเริ่มบทสนทนานี้ได้')),
    );
    return;
  }
  Navigator.push<void>(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChatRoomScreen(
        conversation: conversation,
        initialDraft: draft ?? kDefaultShopInquiryDraft,
      ),
    ),
  );
}

const List<String> _weekdayNames = [
  'วันจันทร์',
  'วันอังคาร',
  'วันพุธ',
  'วันพฤหัสบดี',
  'วันศุกร์',
  'วันเสาร์',
  'วันอาทิตย์',
];

/// Public storefront of a shop account.
class ShopProfileScreen extends StatelessWidget {
  final String shopUserId;
  final String? inquiryDraft;

  /// Source of "now" (defaults to [DateTime.now]); converted to Thailand time.
  final DateTime Function()? clock;

  const ShopProfileScreen({
    super.key,
    required this.shopUserId,
    this.inquiryDraft,
    this.clock,
  });

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.userById(shopUserId);
        final shop = user?.shop;
        if (user == null || !user.isShop || shop == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('โปรไฟล์ร้านค้า')),
            body: const Center(child: Text('ไม่พบข้อมูลร้านค้านี้')),
          );
        }
        final thaiTime = toThaiTime((clock ?? DateTime.now)());
        final isOpen = shop.openingHours.isOpenAt(thaiTime);
        final isOwnShop = appState.currentUser.id == user.id;
        final distance = distanceKm(appState.currentLocation, shop.location);
        final listings = [
          for (final product in appState.products)
            if (product.sellerId == user.id &&
                product.status == ListingStatus.active)
              NearbyProduct(
                product: product,
                distanceKm: distanceKm(
                  appState.currentLocation,
                  product.publicLocation,
                ),
              ),
        ];
        final reviews = appState.reviewsForUser(user.id).take(10).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('โปรไฟล์ร้านค้า')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.aquaPale,
                  child: Icon(
                    Icons.storefront_outlined,
                    size: 38,
                    color: AppColors.deepNavy,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Center(child: ShopBadge()),
              if (shop.description.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  shop.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.deepNavy),
                ),
              ],
              if (shop.categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final category in shop.categories)
                      Chip(
                        label: Text(
                          category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.near_me_outlined,
                    size: 16,
                    color: AppColors.oceanBlue,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      shop.locationLabel.isEmpty
                          ? formatDistance(distance)
                          : '${formatDistance(distance)} · ${shop.locationLabel}',
                      style: const TextStyle(color: AppColors.graySecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: isOpen ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOpen
                        ? 'เปิดอยู่ · ตามเวลาที่ร้านแจ้ง'
                        : 'ปิดอยู่ · ตามเวลาที่ร้านแจ้ง',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isOpen ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              if (!isOwnShop) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => startShopInquiry(
                    context,
                    appState,
                    user.id,
                    draft: inquiryDraft,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('ทักถามร้าน'),
                ),
              ],
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เวลาเปิดทำการ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (var day = 1; day <= 7; day++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Expanded(child: Text(_weekdayNames[day - 1])),
                              Text(
                                _hoursLabel(shop.openingHours.days[day]),
                                style: const TextStyle(
                                  color: AppColors.graySecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!isOwnShop) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ReportScreen(
                              targetUserId: user.id,
                              targetName: user.displayName,
                            ),
                          ),
                        ),
                        icon: const Icon(
                          Icons.flag_outlined,
                          color: AppColors.error,
                        ),
                        label: const Text('รายงานผู้ใช้'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final blocked = appState.isBlocked(user.id);
                          final error = blocked
                              ? appState.unblockUser(user.id)
                              : appState.blockUser(user.id);
                          if (error != null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        },
                        icon: const Icon(Icons.block_outlined),
                        label: Text(
                          appState.isBlocked(user.id) ? 'ปลดบล็อก' : 'บล็อก',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'สินค้าของร้าน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              const SizedBox(height: 8),
              if (listings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'ร้านนี้ยังไม่มีสินค้าที่เปิดขาย',
                    style: TextStyle(color: AppColors.graySecondary),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: productCardGridAspectRatio(
                      MediaQuery.textScalerOf(context),
                    ),
                  ),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final nearby = listings[index];
                    return ProductCard(
                      nearbyProduct: nearby,
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ProductDetailScreen(
                            product: nearby.product,
                            nearbyDistanceKm: nearby.distanceKm,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              const Text(
                'รีวิวล่าสุด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepNavy,
                ),
              ),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'ยังไม่มีรีวิว',
                    style: TextStyle(color: AppColors.graySecondary),
                  ),
                )
              else
                ...reviews.map((review) {
                  final reviewer = appState.userById(review.reviewerId);
                  return Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(reviewer?.displayName ?? 'ผู้ใช้ชุมชน'),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                            size: 17,
                          ),
                          Text('${review.rating}'),
                        ],
                      ),
                      subtitle: Text(
                        review.comment.isEmpty
                            ? review.tags.join(' · ')
                            : review.comment,
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  static String _hoursLabel(DayHours? hours) {
    if (hours == null) return 'ปิด';
    String format(int minute) =>
        '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}';
    return '${format(hours.openMinute)} - ${format(hours.closeMinute)}'
        '${hours.isOvernight ? ' (วันถัดไป)' : ''}';
  }
}
