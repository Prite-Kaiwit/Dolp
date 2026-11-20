// Legacy order fields remain until the order-flow migration in phase 6.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../review_safety/rate_review_screen.dart';
import '../review_safety/report_screen.dart';
import '../main_navigation_screen.dart';

class EscrowStatusScreen extends StatelessWidget {
  final String orderId;

  const EscrowStatusScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('สถานะคำสั่งซื้อ'),
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final order = appState.orders.firstWhere(
            (o) => o.id == orderId,
            orElse: () => appState.orders.first,
          );

          final currentStep = order.status.stepIndex;
          final isDisputed = order.status == OrderStatus.disputed;
          final isCompleted = order.status == OrderStatus.completed;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID & Status Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDisputed
                          ? AppColors.error.withValues(alpha: 0.1)
                          : isCompleted
                          ? AppColors.greenPale
                          : AppColors.pinkPale,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDisputed
                            ? AppColors.error
                            : isCompleted
                            ? AppColors.greenPrimary
                            : AppColors.pinkPrimary,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDisputed
                              ? Icons.warning_amber_rounded
                              : isCompleted
                              ? Icons.task_alt_rounded
                              : Icons.shield_rounded,
                          color: isDisputed
                              ? AppColors.error
                              : isCompleted
                              ? AppColors.greenPrimary
                              : AppColors.pinkPrimary,
                          size: 32,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.status.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDisputed
                                      ? AppColors.error
                                      : isCompleted
                                      ? AppColors.greenDark
                                      : AppColors.pinkDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'รหัสคำสั่งซื้อ: ${order.id}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4-Step Escrow Timeline (UC-02)
                  const Text(
                    'ไทม์ไลน์ระบบพักเงิน Escrow 4 ขั้นตอน',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  _buildTimelineStep(
                    stepNumber: 1,
                    title: 'พักเงินในระบบ (Escrow Protected)',
                    desc:
                        'ผู้ซื้อชำระเงินเรียบร้อยแล้ว เงินจะถูกคุ้มครองไว้ในบัญชีกลาง',
                    isDone: currentStep >= 1 || isCompleted,
                    isCurrent: currentStep == 1 && !isDisputed,
                  ),
                  _buildTimelineStep(
                    stepNumber: 2,
                    title: 'นัดรับสินค้า',
                    desc:
                        'จุดนัดรับ: ${order.pickupPoint}\nเวลานัด: ${order.scheduledTime}',
                    isDone: currentStep >= 2 || isCompleted,
                    isCurrent: currentStep == 2 && !isDisputed,
                  ),
                  _buildTimelineStep(
                    stepNumber: 3,
                    title: 'ผู้ซื้อตรวจรับสินค้า & ยืนยัน',
                    desc: 'ตรวจสอบสินค้าจริง หากถูกต้องให้กดยืนยันรับสินค้า',
                    isDone: currentStep >= 3 || isCompleted,
                    isCurrent: currentStep == 3 && !isDisputed,
                  ),
                  _buildTimelineStep(
                    stepNumber: 4,
                    title: 'ปล่อยเงินโอนเข้าบัญชีผู้ขาย (สำเร็จ)',
                    desc:
                        'ระบบปลดล็อกเงินและโอนเข้าบัญชีผู้ขาย ธุรกรรมเสร็จสมบูรณ์',
                    isDone: isCompleted,
                    isCurrent: isCompleted,
                    isLast: true,
                  ),
                  const SizedBox(height: 24),

                  // Product & Seller Details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.grayBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.grayLine),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                order.productImageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.pinkPale,
                                  width: 56,
                                  height: 56,
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
                                    'ยอดเงิน: ฿${order.productPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppColors.pinkPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'ผู้ขาย: ${order.sellerName}',
                                    style: const TextStyle(
                                      color: AppColors.graySecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (order.note.isNotEmpty) ...[
                          const Divider(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.note_alt_outlined,
                                size: 14,
                                color: AppColors.graySecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'โน้ต: ${order.note}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons Based on Order State
                  if (!isCompleted && !isDisputed) ...[
                    // Confirm Receiving Goods Button (Transitions Escrow step to Completed!)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'ฉันได้รับและตรวจรับสินค้าเรียบร้อยแล้ว (ปล่อยเงิน)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenPrimary,
                        ),
                        onPressed: () {
                          _showConfirmReceiptDialog(context, appState, order);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dispute / Report Button (UC-03)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'รายงานปัญหา / ขอระงับการจ่ายเงิน (Dispute)',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(
                                orderId: order.id,
                                targetName: order.sellerName,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else if (isCompleted) ...[
                    // Completed State: Rate & Review button (FR-07)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'ให้คะแนนและรีวิวผู้ขาย (Rate & Review)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pinkPrimary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RateReviewScreen(order: order),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else if (isDisputed) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.grayBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'รายงานนี้ส่งให้ทีมดูแลตรวจสอบข้อมูลและหลักฐานที่เกี่ยวข้องแล้ว',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.graySecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String desc,
    required bool isDone,
    required bool isCurrent,
    bool isLast = false,
  }) {
    Color circleColor = AppColors.grayLine;
    Color textColor = AppColors.graySecondary;
    Widget icon = Text(
      '$stepNumber',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.graySecondary,
      ),
    );

    if (isDone) {
      circleColor = AppColors.greenPrimary;
      textColor = AppColors.inkText;
      icon = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isCurrent) {
      circleColor = AppColors.pinkPrimary;
      textColor = AppColors.pinkDark;
      icon = Text(
        '$stepNumber',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: icon),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.greenPrimary : AppColors.grayLine,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.graySecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmReceiptDialog(
    BuildContext context,
    AppState appState,
    OrderModel order,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.greenPrimary),
            SizedBox(width: 8),
            Text('ยืนยันรับสินค้า?'),
          ],
        ),
        content: const Text(
          'คุณได้ตรวจสอบสินค้าจริง ณ จุดนัดรับ และพบว่าถูกต้องตรงตามที่ระบุใช่หรือไม่?\n\nเมื่อยืนยันแล้ว ระบบจะปล่อยเงินโอนให้ผู้ขายทันทีและไม่สามารถเรียกคืนได้',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตรวจสอบอีกครั้ง'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.confirmBuyerReceived(order.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'ยืนยันรับสินค้าสำเร็จ! ปล่อยเงินให้ผู้ขายเรียบร้อยแล้ว',
                  ),
                  backgroundColor: AppColors.greenPrimary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenPrimary,
            ),
            child: const Text('ยืนยันและปล่อยเงิน'),
          ),
        ],
      ),
    );
  }
}
