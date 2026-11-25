import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/meetup_sharing.dart';
import '../../widgets/order_status_badge.dart';
import '../../widgets/product_image.dart';
import '../../widgets/safety_tips_sheet.dart';
import '../chat/chat_room_screen.dart';
import '../profile/public_user_profile_screen.dart';
import '../review_safety/rate_review_screen.dart';
import '../review_safety/report_screen.dart';

class OrderStatusScreen extends StatelessWidget {
  final String orderId;

  const OrderStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(title: const Text('สถานะคำสั่งซื้อ')),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final order = appState.orders
              .where((item) => item.id == orderId)
              .firstOrNull;
          if (order == null) {
            return const Center(child: Text('ไม่พบคำสั่งซื้อนี้'));
          }
          final isBuyer = appState.currentUser.id == order.buyerId;
          final isSeller = appState.currentUser.id == order.sellerId;
          final otherUserId = isBuyer ? order.sellerId : order.buyerId;
          final otherUser = appState.userById(otherUserId);
          final isParticipant = isBuyer || isSeller;
          final hasDisputeWindow =
              order.status == OrderStatus.pending ||
              (order.status == OrderStatus.completed &&
                  order.completedAt != null &&
                  DateTime.now().difference(order.completedAt!) <=
                      const Duration(days: 7));
          final participantsBlocked =
              isParticipant && appState.isBlocked(otherUserId);
          final canReview =
              order.status == OrderStatus.completed &&
              (isBuyer || isSeller) &&
              !appState.hasReviewedOrder(order.id, appState.currentUser.id);
          final sharedAddress = appState.sharedAddressForOrder(order.id);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                _buildTimeline(order),
                const SizedBox(height: 12),
                if (participantsBlocked)
                  Card(
                    color: AppColors.warningPale,
                    child: const ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: AppColors.warningDark,
                      ),
                      title: Text('ผู้ซื้อและผู้ขายบล็อกกัน'),
                      subtitle: Text(
                        'ออเดอร์เดิมยังไม่ถูกยกเลิก คุณยังยกเลิกหรือรายงานปัญหาได้',
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: otherUser == null
                              ? null
                              : () => Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => PublicUserProfileScreen(
                                      userId: otherUserId,
                                    ),
                                  ),
                                ),
                          child: Text(
                            '${isBuyer ? 'ผู้ขาย' : 'ผู้ซื้อ'}: ${otherUser?.name ?? otherUserId}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepNavy,
                            ),
                          ),
                        ),
                        Text(
                          'วิธีชำระ: ${order.paymentMethod.label}',
                          style: const TextStyle(
                            color: AppColors.graySecondary,
                          ),
                        ),
                        const Divider(height: 20),
                        ...order.items.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 52,
                                height: 52,
                                child: ProductImage(
                                  source: item.coverImage,
                                  fallbackUrl: item.coverImage?.url ?? '',
                                ),
                              ),
                            ),
                            title: Text(item.title),
                            subtitle: Text(
                              item.listingType.name == 'donate'
                                  ? 'ฟรี'
                                  : '฿${item.price.toStringAsFixed(2)}',
                            ),
                          ),
                        ),
                        const Divider(height: 20),
                        Text('ยอดรวม ฿${order.totalPrice.toStringAsFixed(2)}'),
                        Text('ประเภทจุดรับ: ${order.pickupType.label}'),
                        if (order.agreedPlaceLabel != null)
                          Text('สถานที่: ${order.agreedPlaceLabel}'),
                        if (order.agreedTime != null)
                          Text(
                            'เวลานัด: ${_formatDateTime(order.agreedTime!)}',
                          ),
                        if (order.cancelReason != null)
                          Text(
                            'เหตุผลยกเลิก: ${order.cancelReason}',
                            style: const TextStyle(color: AppColors.error),
                          ),
                      ],
                    ),
                  ),
                ),
                if (sharedAddress != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    color: AppColors.successPale,
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.successDark,
                      ),
                      title: const Text('ที่อยู่ที่ผู้ขายแชร์ในแชท'),
                      subtitle: Text(sharedAddress),
                      trailing: IconButton(
                        tooltip: 'ไปแชท',
                        onPressed: () => _openChat(context, appState, order.id),
                        icon: const Icon(Icons.chat_outlined),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _openChat(context, appState, order.id),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('ไปแชท'),
                ),
                OutlinedButton.icon(
                  onPressed: () => showSafetyTipsSheet(context, force: true),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('คำแนะนำก่อนนัดรับ'),
                ),
                if (order.meetupId != null &&
                    order.agreedPlaceLabel != null &&
                    order.agreedTime != null)
                  OutlinedButton.icon(
                    onPressed: () async =>
                        shareOrderMeetupPlan(appState, order),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('แชร์แผนนัด'),
                  ),
                if (order.status == OrderStatus.pending && isSeller) ...[
                  ElevatedButton(
                    onPressed: () {
                      final error = appState.markOrderHandedOver(order.id);
                      _showResult(context, error, 'บันทึกการส่งมอบแล้ว');
                    },
                    child: const Text('ยืนยันส่งมอบ'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _showCancelDialog(context, appState, order),
                    child: const Text('ยกเลิก'),
                  ),
                ],
                if (order.status == OrderStatus.pending && isBuyer)
                  ElevatedButton(
                    onPressed: () =>
                        _confirmReceipt(context, appState, order.id),
                    child: const Text('ได้รับสินค้าแล้ว'),
                  ),
                if (order.status == OrderStatus.pending && isBuyer)
                  OutlinedButton(
                    onPressed: () =>
                        _showCancelDialog(context, appState, order),
                    child: const Text('ยกเลิก'),
                  ),
                if (hasDisputeWindow && isParticipant)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ReportScreen(
                          orderId: order.id,
                          targetUserId: otherUserId,
                          targetName: otherUser?.name ?? otherUserId,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.report_outlined,
                      color: AppColors.error,
                    ),
                    label: const Text('รายงานปัญหา'),
                  ),
                if (canReview)
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RateReviewScreen(order: order),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('ให้คะแนน'),
                  ),
                if (order.status == OrderStatus.disputed)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'รายงานปัญหานี้อยู่ระหว่างการตรวจสอบ',
                      style: TextStyle(color: AppColors.warningDark),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final steps = [
      ('ตกลงแล้ว', true),
      ('นัดรับ', order.meetupId != null || order.agreedPlaceLabel != null),
      ('รับของแล้ว', order.handedOverAt != null || order.completedAt != null),
      ('รีวิว', order.status == OrderStatus.completed),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ความคืบหน้า',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final (label, done) in steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: done ? AppColors.success : AppColors.graySecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReceipt(
    BuildContext context,
    AppState appState,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ยืนยันว่าได้รับสินค้าแล้ว?'),
        content: const Text('โปรดตรวจสอบสินค้าและตกลงชำระเงินกับผู้ขายหน้างาน'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('กลับ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = appState.completeOrder(id);
    _showResult(context, error, 'คำสั่งซื้อสำเร็จ');
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    AppState appState,
    OrderModel order,
  ) async {
    const reasons = [
      'เปลี่ยนใจ',
      'นัดหมายไม่สะดวก',
      'สินค้าไม่พร้อม',
      'อื่น ๆ',
    ];
    var reason = reasons.first;
    final noteController = TextEditingController();
    final selectedReason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ยกเลิกคำสั่งซื้อ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                items: reasons
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => reason = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                maxLength: 200,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'หมายเหตุเพิ่มเติม (ไม่เกิน 200 ตัวอักษร)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('กลับ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                noteController.text.trim().isEmpty
                    ? reason
                    : '$reason: ${noteController.text.trim()}',
              ),
              child: const Text('ยืนยันยกเลิก'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (selectedReason == null || !context.mounted) return;
    final error = appState.cancelOrder(order.id, selectedReason);
    _showResult(context, error, 'ยกเลิกคำสั่งซื้อแล้ว');
  }

  Future<void> _openChat(
    BuildContext context,
    AppState appState,
    String id,
  ) async {
    final conversation = appState.conversationForOrder(id);
    if (conversation == null) {
      _showResult(context, 'เปิดบทสนทนาไม่ได้', '');
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatRoomScreen(conversation: conversation),
      ),
    );
  }

  void _showResult(BuildContext context, String? error, String success) {
    final message = error ?? success;
    if (message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year} $hour:$minute';
  }
}
