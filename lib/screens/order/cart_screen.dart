import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import 'pickup_point_screen.dart';

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
              onPressed: () => appState.clearCart(),
              child: const Text(
                'ล้างตะกร้า',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.pinkPale,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove_shopping_cart_outlined,
                      size: 56,
                      color: AppColors.pinkPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ไม่มีสินค้าในตะกร้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'เลือกดูสินค้ามือสองและของใช้ใกล้คุณได้ที่หน้าแรก',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.graySecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('กลับไปช้อปปิ้ง'),
                  ),
                ],
              ),
            );
          }

          final total = appState.cartItems.fold<double>(
            0,
            (sum, item) => sum + item.price,
          );

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: appState.cartItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = appState.cartItems[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.type == ListingType.donate
                                        ? 'ส่งต่อฟรี'
                                        : '฿${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.pinkPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'จุดรับ: ${item.pickupPoint}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.graySecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              onPressed: () => appState.removeFromCart(item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Checkout Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ยอดรวมทั้งหมด',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '฿${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pinkPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.shield_rounded,
                            color: AppColors.greenPrimary,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'คุ้มครองด้วยระบบพักเงิน Escrow ทุกออเดอร์',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greenDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Proceed with first cart item as checkout demo
                            final first = appState.cartItems.first;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PickupPointScreen(product: first),
                              ),
                            );
                          },
                          child: const Text(
                            'ดำเนินการสั่งซื้อ (เลือกจุดนัดรับ)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
