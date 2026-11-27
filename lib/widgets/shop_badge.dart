import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small pill marking a shop account.
class ShopBadge extends StatelessWidget {
  const ShopBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.aquaPale,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.oceanBlue),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 11, color: AppColors.oceanBlue),
          SizedBox(width: 3),
          Text(
            'ร้านค้า',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.oceanBlue,
            ),
          ),
        ],
      ),
    );
  }
}
