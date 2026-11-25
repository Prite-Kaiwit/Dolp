import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/product_image.dart';
import '../chat/chat_room_screen.dart';
import 'order_status_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String sellerId;

  const OrderSummaryScreen({super.key, required this.sellerId});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  PaymentMethod? _paymentMethod;

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(title: const Text('สรุปการสั่งซื้อ')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final items = appState.cartItems
              .where((item) => item.sellerId == widget.sellerId)
              .toList();
          if (items.isEmpty) {
            return const Center(
              child: Text('รายการนี้ไม่มีสินค้าในตะกร้าแล้ว'),
            );
          }
          final sellerName = items.first.sellerName;
          final total = items.fold<double>(0, (sum, item) => sum + item.price);
          final meetup = appState.acceptedMeetupForSeller(
            widget.sellerId,
            items.map((item) => item.id).toSet(),
          );
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'ผู้ขาย: $sellerName',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map(_buildItem),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'การนัดรับ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ประเภทจุดรับ: ${meetup?.pickupType.label ?? items.first.pickupType.label}',
                              ),
                              if (meetup != null) ...[
                                Text('สถานที่: ${meetup.placeLabel}'),
                                Text(
                                  'เวลา: ${_formatDateTime(meetup.scheduledAt)}',
                                ),
                              ] else ...[
                                const Text('ยังไม่ได้นัดรับ ไปตกลงในแชท'),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      final conversation = appState
                                          .openConversationForProduct(
                                            items.first.id,
                                          );
                                      if (conversation == null) {
                                        _showMessage('เปิดบทสนทนาไม่ได้');
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => ChatRoomScreen(
                                            conversation: conversation,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.chat_outlined),
                                    label: const Text('ไปแชทกับผู้ขาย'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'เลือกวิธีชำระเงิน',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      RadioGroup<PaymentMethod>(
                        groupValue: _paymentMethod,
                        onChanged: (value) =>
                            setState(() => _paymentMethod = value),
                        child: const Column(
                          children: [
                            RadioListTile<PaymentMethod>(
                              value: PaymentMethod.cashOnHandover,
                              title: Text('เงินสดหน้างาน'),
                            ),
                            RadioListTile<PaymentMethod>(
                              value: PaymentMethod.transferOnHandover,
                              title: Text('โอนตอนรับของ'),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warningPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'ตรวจสินค้าก่อนจ่ายเงิน ไม่โอนก่อนเห็นของถ้าไม่มั่นใจ',
                          style: TextStyle(color: AppColors.warningDark),
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ยอดรวม',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '฿${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.oceanBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _paymentMethod == null
                                ? null
                                : () => _createOrder(appState),
                            child: const Text('ยืนยันคำสั่งซื้อ'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(ProductModel item) {
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 52,
            child: ProductImage.forProduct(item),
          ),
        ),
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          item.type == ListingType.donate
              ? 'ฟรี'
              : '฿${item.price.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  Future<void> _createOrder(AppState appState) async {
    final paymentMethod = _paymentMethod;
    if (paymentMethod == null) return;
    final result = appState.createOrderForSeller(
      widget.sellerId,
      paymentMethod: paymentMethod,
    );
    if (!mounted) return;
    if (!result.isSuccess) {
      _showMessage(result.error ?? 'สร้างคำสั่งซื้อไม่สำเร็จ');
      return;
    }
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OrderStatusScreen(orderId: result.order!.id),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date = '${local.day}/${local.month}/${local.year}';
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }
}
