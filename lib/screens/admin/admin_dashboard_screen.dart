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
          final totalEscrowVolume = appState.orders.fold<double>(
            0,
            (sum, o) => sum + o.productPrice,
          );

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
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'แดชบอร์ดความปลอดภัย & ระบบพักเงิน',
                        style: TextStyle(
                          color: Colors.white,
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
                      'ยอดเงินใน Escrow',
                      '฿${totalEscrowVolume.toStringAsFixed(0)}',
                      Icons.account_balance_wallet_outlined,
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

                // Transactions Trend Chart Simulator
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ปริมาณธุรกรรมพักเงินรายสัปดาห์ (Escrow Volume)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '7 วันล่าสุด',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.graySecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar('จันทร์', 45, '฿4.5k'),
                          _buildBar('อังคาร', 60, '฿6.0k'),
                          _buildBar('พุธ', 35, '฿3.5k'),
                          _buildBar('พฤหัส', 80, '฿8.0k'),
                          _buildBar('ศุกร์', 100, '฿10.2k', isHighlight: true),
                          _buildBar('เสาร์', 55, '฿5.5k'),
                          _buildBar('อาทิตย์', 40, '฿4.0k'),
                        ],
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
                      'จัดการรายงาน & ข้อพิพาท Escrow',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'ตรวจสอบหลักฐาน และตัดสินคืนเงิน/ปล่อยเงิน ($pendingReports เคสรอดำเนินการ)',
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

  Widget _buildBar(
    String day,
    double height,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 9,
            color: isHighlight ? AppColors.oceanBlue : AppColors.graySecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            color: isHighlight ? AppColors.oceanBlue : AppColors.successLight,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: const TextStyle(fontSize: 10, color: AppColors.graySecondary),
        ),
      ],
    );
  }
}
