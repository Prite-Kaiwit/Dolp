import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/app_theme.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      OrderStatus.pending => (AppColors.warningPale, AppColors.warningDark),
      OrderStatus.completed => (AppColors.successPale, AppColors.successDark),
      OrderStatus.cancelled => (AppColors.errorPale, AppColors.error),
      OrderStatus.disputed => (AppColors.errorPale, AppColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.title,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
    final background = isDonate
        ? AppColors.listingDonate
        : isTrade
        ? AppColors.listingExchange
        : AppColors.listingSale;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
