import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../widgets/product_image.dart';
import 'order_summary_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตะกร้าสินค้าของฉัน'),
        actions: [
          if (appState.cartItems.isNotEmpty)
            TextButton(
              onPressed: appState.clearCart,
              child: const Text('ล้างตะกร้า'),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.cartItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 56,
                    color: AppColors.graySecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'ไม่มีสินค้าในตะกร้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text('เลือกสินค้าที่ต้องการจากหน้าแรก'),
                ],
              ),
            );
          }

          final groups = <String, List<ProductModel>>{};
          for (final item in appState.cartItems) {
            groups.putIfAbsent(item.sellerId, () => []).add(item);
          }
          final sellers = groups.keys.toList();
          final total = appState.cartItems.fold<double>(
            0,
            (sum, item) => sum + item.price,
          );
          return Column(
            children: [
              if (groups.length > 1)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'สินค้าอยู่คนละที่ ต้องนัดรับแยกกัน',
                    style: TextStyle(
                      color: AppColors.warningDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sellers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sellerId = sellers[index];
                    final items = groups[sellerId]!;
                    final sellerTotal = items.fold<double>(
                      0,
                      (sum, item) => sum + item.price,
                    );
                    final unavailable = items.any(
                      (item) =>
                          appState.cartItemUnavailableReason(item) != null,
                    );
                    final first = items.first;
                    final distance = distanceKm(
                      appState.currentLocation,
                      first.publicLocation,
                    );
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              first.sellerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'ผู้ขายอยู่ห่างประมาณ ${formatDistance(distance)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.graySecondary,
                              ),
                            ),
                            const Divider(height: 20),
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: ProductImage.forProduct(item),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            item.type == ListingType.donate
                                                ? 'ฟรี'
                                                : '฿${item.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: AppColors.oceanBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (appState
                                                  .cartItemUnavailableReason(
                                                    item,
                                                  )
                                              case final reason?)
                                            Text(
                                              reason,
                                              style: const TextStyle(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'นำออกจากตะกร้า',
                                      onPressed: () =>
                                          appState.removeFromCart(item.id),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              children: [
                                const Text('ยอดรวมผู้ขายนี้'),
                                Text(
                                  '฿${sellerTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: AppColors.oceanBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: unavailable
                                    ? null
                                    : () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => OrderSummaryScreen(
                                            sellerId: sellerId,
                                          ),
                                        ),
                                      ),
                                child: const Text('ตกลงซื้อกับผู้ขายนี้'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ยอดรวมในตะกร้า',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '฿${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.oceanBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
