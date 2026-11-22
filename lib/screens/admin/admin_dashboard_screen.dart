import 'package:flutter/material.dart';

import '../../constants/app_info.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/report.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_route_guard.dart';
import 'admin_disputes_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    if (!appState.isAdmin) {
      return const AdminRouteGuard(child: SizedBox.shrink());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('$appName | Admin'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successPale,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, size: 15, color: AppColors.successDark),
                SizedBox(width: 4),
                Text(
                  'ผู้ดูแลระบบ',
                  style: TextStyle(
                    color: AppColors.successDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final openReports = appState.reports
              .where((report) => report.status == ReportStatus.open)
              .length;
          final disputed = appState.orders
              .where((order) => order.status == OrderStatus.disputed)
              .length;
          final activeListings = appState.products
              .where((product) => product.status == ListingStatus.active)
              .length;
          final newToday = appState.products
              .where((product) => !product.createdAt.isBefore(today))
              .length;
          final counts = List<int>.generate(7, (index) {
            final day = DateTime(now.year, now.month, now.day)
                .subtract(Duration(days: 6 - index));
            final nextDay = day.add(const Duration(days: 1));
            return appState.products
                .where(
                  (product) =>
                      !product.createdAt.isBefore(day) &&
                      product.createdAt.isBefore(nextDay),
                )
                .length;
          });
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.deepNavy,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$appName · จัดการชุมชน',
                      style: TextStyle(color: AppColors.white, fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'แดชบอร์ดรายงานและการจัดการ',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'สถิติระบบ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _metric('ผู้ใช้', '${appState.users.length}', Icons.people_outline, AppColors.oceanBlue),
                  _metric('รายงานรอตรวจ', '$openReports', Icons.flag_outlined, AppColors.warningDark),
                  _metric('ข้อพิพาทรอจัดการ', '$disputed', Icons.gavel_outlined, AppColors.error),
                  _metric('ประกาศกำลังขาย', '$activeListings', Icons.storefront_outlined, AppColors.oceanBlue),
                  _metric('สินค้าใหม่วันนี้', '$newToday', Icons.fiber_new_outlined, AppColors.aqua),
                  _metric('ออเดอร์รอนัดรับ', '${appState.pendingOrderCount}', Icons.handshake_outlined, AppColors.warningDark),
                  _metric('ออเดอร์สำเร็จ', '${appState.completedOrderCount}', Icons.task_alt_outlined, AppColors.successDark),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'โพสต์ใหม่ต่อวัน · 7 วันล่าสุด',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      for (var index = 0; index < counts.length; index++)
                        _DailyBar(
                          label: _dayLabel(now.subtract(Duration(days: 6 - index))),
                          count: counts[index],
                          maxCount: counts.fold<int>(0, (a, b) => a > b ? a : b),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'เมนูจัดการ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.error),
                  title: const Text('รายงานและข้อพิพาท'),
                  subtitle: Text('$openReports รายงานรอตรวจ · $disputed ข้อพิพาท'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminDisputesScreen(),
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.manage_accounts_outlined, color: AppColors.oceanBlue),
                  title: const Text('จัดการผู้ใช้'),
                  subtitle: const Text('ค้นหา ระงับ และปลดระงับบัญชี'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminUsersScreen(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
                Icon(icon, size: 19, color: color),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime value) =>
      '${value.day}/${value.month}';
}

class _DailyBar extends StatelessWidget {
  final String label;
  final int count;
  final int maxCount;

  const _DailyBar({
    required this.label,
    required this.count,
    required this.maxCount,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 42, child: Text(label, style: const TextStyle(fontSize: 11))),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              color: AppColors.oceanBlue,
              backgroundColor: AppColors.aquaPale,
            ),
          ),
          SizedBox(
            width: 26,
            child: Text('$count', textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}
