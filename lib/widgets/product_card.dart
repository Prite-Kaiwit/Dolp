import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'escrow_badge.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.grayLine.withValues(alpha: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: AspectRatio(
                    aspectRatio: 1.1,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.pinkPale,
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: AppColors.pinkLight),
                        ),
                      ),
                    ),
                  ),
                ),
                // Type badge on top left
                Positioned(
                  top: 8,
                  left: 8,
                  child: ListingTypeBadge(
                    label: product.type.label,
                    isTrade: product.type == ListingType.trade,
                    isDonate: product.type == ListingType.donate,
                  ),
                ),
                // Escrow mini indicator top right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 14,
                      color: AppColors.greenPrimary,
                    ),
                  ),
                ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkText,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price or Trade Info
                  if (product.type == ListingType.donate)
                    const Text(
                      'ส่งต่อฟรี (Free)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.greenDark,
                      ),
                    )
                  else if (product.type == ListingType.trade)
                    Text(
                      'แลกเปลี่ยน / ฿${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    )
                  else
                    Text(
                      '฿${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pinkPrimary,
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Pickup Point snippet
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppColors.graySecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product.pickupPoint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.graySecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Seller Rating
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.pinkPale,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 12, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(
                              product.sellerRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.inkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${product.favoriteCount} ชื่นชอบ',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.graySecondary,
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
    );
  }
}
