import 'package:flutter/material.dart';
import '../../constants/app_info.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import 'admin_disputes_screen.dart';
import 'admin_pickup_points_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        title: Text('$appName | Admin Dashboard'),
        backgroundColor: AppColors.white,
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
                Icon(Icons.security, size: 14, color: AppColors.successDark),
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
          final pendingReports = appState.reports
              .where((r) => r.status.index <= 1)
              .length;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Welcome Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.successDark, AppColors.success],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$appName · ระบบจัดการชุมชน',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '🟢 ระบบปกติ',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'แดชบอร์ดรายงานและการจัดการคำสั่งซื้อ',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ดูแลการใช้งานและรายงานจากสมาชิกในชุมชน',
                        style: TextStyle(color: AppColors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Key Performance Metrics Grid
                const Text(
                  'สถิติรวมของระบบ (Key Metrics)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMetricCard(
                      'ออเดอร์รอนัดรับ',
                      '${appState.pendingOrderCount} รายการ',
                      Icons.handshake_outlined,
                      AppColors.warning,
                    ),
                    _buildMetricCard(
                      'ออเดอร์สำเร็จ',
                      '${appState.completedOrderCount} รายการ',
                      Icons.task_alt_outlined,
                      AppColors.success,
                    ),
                    _buildMetricCard(
                      'ข้อพิพาทรอดำเนินการ',
                      '$pendingReports รายการ',
                      Icons.report_problem_outlined,
                      AppColors.error,
                      hasAlert: pendingReports > 0,
                    ),
                    _buildMetricCard(
                      'สินค้าที่เปิดขายอยู่',
                      '${appState.products.length} รายการ',
                      Icons.shopping_bag_outlined,
                      AppColors.oceanBlue,
                    ),
                    _buildMetricCard(
                      'จุดนัดรับแนะนำ',
                      '${appState.pickupPoints.length} จุด',
                      Icons.location_on_outlined,
                      AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grayLine),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TODO เฟส 7: เพิ่มกราฟจำนวนคำสั่งซื้อต่อวัน',
                        style: TextStyle(
                          color: AppColors.graySecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Management Actions
                const Text(
                  'เมนูจัดการสำหรับแอดมิน',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Dispute Manager Card
                Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDisputesScreen(),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.gavel_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    title: const Text(
                      'จัดการรายงานและปัญหา',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'ตรวจสอบรายงานจากสมาชิก ($pendingReports เคสรอดำเนินการ)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Pickup Points Manager Card
                Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminPickupPointsScreen(),
                        ),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successPale,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: AppColors.successDark,
                      ),
                    ),
                    title: const Text(
                      'จัดการจุดนัดรับแนะนำ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'เพิ่ม / แก้ไข / ระงับจุดนัดรับแนะนำในพื้นที่',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool hasAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAlert ? AppColors.error : AppColors.grayLine,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.graySecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

}
