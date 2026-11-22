import 'package:flutter/material.dart';

import '../../models/notification.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_room_screen.dart';
import '../home/product_detail_screen.dart';
import '../order/order_status_screen.dart';
import 'my_reports_screen.dart';
import 'area_alert_settings_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          IconButton(
            tooltip: 'ตั้งค่าแจ้งเตือนในพื้นที่',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AreaAlertSettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
          ),
          TextButton(
            onPressed: appState.markAllNotificationsRead,
            child: const Text('อ่านทั้งหมด'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final notifications = appState.notificationsForCurrentUser();
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: AppColors.graySecondary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ยังไม่มีการแจ้งเตือน',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final (icon, color) = _styleFor(notification.type);
              return Dismissible(
                key: ValueKey(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppColors.white,
                  ),
                ),
                onDismissed: (_) =>
                    appState.deleteNotification(notification.id),
                child: Card(
                  color: notification.isRead
                      ? AppColors.white
                      : AppColors.aquaPale.withValues(alpha: 0.3),
                  child: ListTile(
                    onTap: () async {
                      appState.markNotificationRead(notification.id);
                      await _openReference(context, appState, notification);
                    },
                    leading: CircleAvatar(
                      backgroundColor: AppColors.aquaPale,
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    subtitle: Text(
                      '${notification.body}\n${_formatTime(notification.createdAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.graySecondary,
                        height: 1.4,
                      ),
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  (IconData, Color) _styleFor(AppNotificationType type) => switch (type) {
    AppNotificationType.newListingNearby => (
      Icons.storefront_outlined,
      AppColors.oceanBlue,
    ),
    AppNotificationType.newMessage => (
      Icons.chat_bubble_outline_rounded,
      AppColors.info,
    ),
    AppNotificationType.meetupProposed ||
    AppNotificationType.meetupResponded => (
      Icons.handshake_outlined,
      AppColors.warningDark,
    ),
    AppNotificationType.orderStatusChanged => (
      Icons.receipt_long_outlined,
      AppColors.oceanBlue,
    ),
    AppNotificationType.reportUpdated => (
      Icons.flag_outlined,
      AppColors.error,
    ),
    AppNotificationType.system => (
      Icons.notifications_outlined,
      AppColors.deepNavy,
    ),
  };

  Future<void> _openReference(
    BuildContext context,
    AppState appState,
    AppNotification notification,
  ) async {
    final referenceId = notification.refId;
    if (referenceId == null) return;
    switch (notification.refType) {
      case 'product':
        final product = appState.products
            .where((item) => item.id == referenceId)
            .firstOrNull;
        if (product != null && context.mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        }
      case 'chat':
        final conversation = appState.conversations
            .where((item) => item.id == referenceId)
            .firstOrNull;
        if (conversation != null && context.mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ChatRoomScreen(conversation: conversation),
            ),
          );
        }
      case 'order':
        if (context.mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (_) => OrderStatusScreen(orderId: referenceId),
            ),
          );
        }
      case 'report':
        if (context.mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (_) => const MyReportsScreen()),
          );
        }
      default:
        return;
    }
  }

  String _formatTime(DateTime time) {
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inMinutes < 1) return 'เมื่อสักครู่';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} นาทีที่แล้ว';
    if (elapsed.inDays < 1) return '${elapsed.inHours} ชั่วโมงที่แล้ว';
    return '${elapsed.inDays} วันที่แล้ว';
  }
}
