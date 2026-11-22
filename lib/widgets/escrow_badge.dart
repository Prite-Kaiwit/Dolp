import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EscrowBadge extends StatelessWidget {
  final bool isCompact;
  const EscrowBadge({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.successPale,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.successLight, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.success,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            isCompact ? 'Escrow พักเงิน' : 'คุ้มครองด้วยระบบพักเงิน (Escrow)',
            style: const TextStyle(
              color: AppColors.successDark,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ListingTypeBadge extends StatelessWidget {
  final String label;
  final bool isTrade;
  final bool isDonate;

  const ListingTypeBadge({
    super.key,
    required this.label,
    this.isTrade = false,
    this.isDonate = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.white;
    Color text = AppColors.listingSale;
    Color border = AppColors.listingSale;

    if (isDonate) {
      bg = AppColors.listingDonate;
      text = AppColors.white;
      border = AppColors.listingDonate;
    } else if (isTrade) {
      bg = AppColors.listingExchange;
      text = AppColors.white;
      border = AppColors.listingExchange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
