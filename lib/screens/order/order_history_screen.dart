import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/product_image.dart';
import 'order_status_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showingPurchases = true;

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
        final userId = appState.currentUser.id;
        final orders = appState.orders.where((order) {
          return _showingPurchases
              ? order.buyerId == userId
              : order.sellerId == userId;
        }).toList();
        final pending = orders
            .where((order) => order.status == OrderStatus.pending)
            .toList();
        final completed = orders
            .where((order) => order.status == OrderStatus.completed)
            .toList();
        final closed = orders
            .where(
              (order) =>
                  order.status == OrderStatus.cancelled ||
                  order.status == OrderStatus.disputed,
            )
            .toList();
        final tabs = [
          ('ทั้งหมด', orders),
          ('รอนัดรับ', pending),
          ('สำเร็จ', completed),
          ('ยกเลิก-มีปัญหา', closed),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('ประวัติการซื้อขาย'),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                for (final (label, list) in tabs)
                  Tab(text: '$label (${list.length})'),
              ],
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('ที่ฉันซื้อ')),
                    ButtonSegment(value: false, label: Text('ที่ฉันขาย')),
                  ],
                  selected: {_showingPurchases},
                  onSelectionChanged: (value) {
                    setState(() => _showingPurchases = value.first);
                  },
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrdersList(orders, appState),
                    _buildOrdersList(pending, appState),
                    _buildOrdersList(completed, appState),
                    _buildOrdersList(closed, appState),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, AppState appState) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'ไม่พบรายการคำสั่งซื้อ',
          style: TextStyle(color: AppColors.graySecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];
        final firstItem = order.items.first;
        final otherPartyId = _showingPurchases ? order.sellerId : order.buyerId;
        final otherParty = appState.userById(otherPartyId);
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => OrderStatusScreen(orderId: order.id),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          order.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
                          ),
                        ),
                      ),
                      OrderStatusBadge(status: order.status),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child: ProductImage(
                            source: firstItem.coverImage,
                            fallbackUrl: firstItem.coverImage?.url ?? '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.items.length == 1
                                  ? firstItem.title
                                  : '${firstItem.title} และอีก ${order.items.length - 1} รายการ',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'คู่รายการ: ${otherParty?.name ?? otherPartyId}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.graySecondary,
                              ),
                            ),
                            Text(
                              'ยอดรวม ฿${order.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.oceanBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('ประเภทจุดรับ: ${order.pickupType.label}'),
                  if (order.agreedPlaceLabel != null)
                    Text('สถานที่: ${order.agreedPlaceLabel}'),
                  if (order.agreedTime != null)
                    Text('เวลานัด: ${_formatDateTime(order.agreedTime!)}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }
}
