// Legacy order fields remain until the order-flow migration in phase 6.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_image.dart';
import '../../state/app_state.dart';
import 'escrow_status_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final allOrders = appState.orders;
        final holdingOrders = allOrders
            .where(
              (o) =>
                  o.status == OrderStatus.escrowHolding ||
                  o.status == OrderStatus.pickupScheduled,
            )
            .toList();
        final completedOrders = allOrders
            .where((o) => o.status == OrderStatus.completed)
            .toList();
        final disputedOrders = allOrders
            .where((o) => o.status == OrderStatus.disputed)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('ประวัติคำสั่งซื้อ & Escrow'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppColors.oceanBlue,
              labelColor: AppColors.oceanBlue,
              unselectedLabelColor: AppColors.graySecondary,
              tabs: [
                Tab(text: 'ทั้งหมด (${allOrders.length})'),
                Tab(text: 'พักเงิน/รอนัดรับ (${holdingOrders.length})'),
                Tab(text: 'สำเร็จแล้ว (${completedOrders.length})'),
                Tab(text: 'มีข้อพิพาท (${disputedOrders.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(allOrders),
              _buildOrdersList(holdingOrders),
              _buildOrdersList(completedOrders),
              _buildOrdersList(disputedOrders),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 54,
              color: AppColors.graySecondary,
            ),
            SizedBox(height: 12),
            Text(
              'ไม่พบรายการคำสั่งซื้อ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isCompleted = order.status == OrderStatus.completed;
        final isDisputed = order.status == OrderStatus.disputed;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EscrowStatusScreen(orderId: order.id),
              ),
            );
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID & Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDisputed
                              ? AppColors.error.withValues(alpha: 0.1)
                              : isCompleted
                              ? AppColors.successPale
                              : AppColors.warningPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isDisputed
                              ? 'มีข้อพิพาท'
                              : isCompleted
                              ? 'สำเร็จ'
                              : 'พักเงิน Escrow',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDisputed
                                ? AppColors.error
                                : isCompleted
                                ? AppColors.successDark
                                : AppColors.warningDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),

                  // Item info
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: ProductImage(
                            source: order.productImage,
                            fallbackUrl: order.productImageUrl,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.productTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ยอดชำระ: ฿${order.productPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.oceanBlue,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'จุดนัดรับ: ${order.pickupPoint}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.graySecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.graySecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
