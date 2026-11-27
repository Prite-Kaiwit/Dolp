import 'package:flutter/material.dart';

import '../models/nearby_shop.dart';
import '../theme/app_theme.dart';
import '../utils/distance.dart';
import 'shop_badge.dart';

/// Search result row for a nearby shop.
class ShopResultCard extends StatelessWidget {
  final NearbyShop nearbyShop;
  final VoidCallback onTap;
  final VoidCallback onAsk;

  /// Whether a search query is active; only then are matching listings counted.
  final bool hasQuery;

  const ShopResultCard({
    super.key,
    required this.nearbyShop,
    required this.onTap,
    required this.onAsk,
    this.hasQuery = false,
  });

  @override
  Widget build(BuildContext context) {
    final shop = nearbyShop.shop;
    final profile = shop.shop;
    final open = nearbyShop.isOpenNow;
    final statusColor = open ? AppColors.success : AppColors.error;
    final detail = hasQuery && nearbyShop.matchingListingCount > 0
        ? 'มีสินค้าตรงคำค้น ${nearbyShop.matchingListingCount} รายการ'
        : 'ร้านขาย: ${(profile?.categories ?? const <String>[]).join(', ')}';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      shop.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const ShopBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    formatDistance(nearbyShop.distanceKm),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.graySecondary,
                    ),
                  ),
                  Text(
                    open ? 'เปิดอยู่' : 'ปิดอยู่',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const Text(
                    'ตามเวลาที่ร้านแจ้ง',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.graySecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.deepNavy),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: onAsk,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('ทักถามร้าน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
