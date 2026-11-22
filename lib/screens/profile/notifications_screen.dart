import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        actions: [
          TextButton(
            onPressed: () {
              for (var n in appState.notifications) {
                n['read'] = true;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ทำเครื่องหมายว่าอ่านทั้งหมดแล้ว'),
                ),
              );
            },
            child: const Text('อ่านทั้งหมด'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.notifications.isEmpty) {
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
                    'ไม่มีการแจ้งเตือนใหม่',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appState.notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = appState.notifications[index];
              final isRead = notif['read'] as bool;
              final type = notif['type'] as String;

              IconData icon = Icons.notifications_rounded;
              Color iconColor = AppColors.oceanBlue;
              Color iconBg = AppColors.aquaPale;

              if (type == 'warning') {
                icon = Icons.warning_amber_rounded;
                iconColor = AppColors.warning;
                iconBg = AppColors.warningPale;
              } else if (type == 'chat') {
                icon = Icons.chat_bubble_outline_rounded;
                iconColor = AppColors.info;
                iconBg = AppColors.aquaPale;
              } else if (type == 'order') {
                icon = Icons.receipt_long_outlined;
                iconColor = AppColors.oceanBlue;
                iconBg = AppColors.aquaPale;
              }

              return Card(
                color: isRead
                    ? Colors.white
                    : AppColors.aquaPale.withValues(alpha: 0.25),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] as String,
                                    style: TextStyle(
                                      fontWeight: isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.deepNavy,
                                    ),
                                  ),
                                ),
                                Text(
                                  notif['time'] as String,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.graySecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif['body'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.graySecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
