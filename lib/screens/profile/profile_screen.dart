import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../constants/app_info.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../home/my_listings_screen.dart';
import '../order/order_history_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/splash_onboarding_screen.dart';
import 'area_alert_settings_screen.dart';
import 'blocked_users_screen.dart';
import 'my_reports_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        final isGuest = user.role == UserRole.guest;
        final isAdmin = user.role == UserRole.admin;

        return Scaffold(
          appBar: AppBar(
            title: const Text('โปรไฟล์ของฉัน'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('เปิดการตั้งค่าแอป')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Avatar & Identity Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.grayLine),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepNavy.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.aquaPale,
                            foregroundImage: NetworkImage(user.avatarUrl),
                            onForegroundImageError: (_, _) {},
                            child: Text(
                              user.name.isNotEmpty ? user.name[0] : 'U',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.oceanBlue,
                              ),
                            ),
                          ),
                          if (user.phoneVerified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.homeLabel.isEmpty
                            ? 'ยังไม่ได้ตั้งค่าพื้นที่'
                            : user.homeLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.graySecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: user.phoneVerified
                              ? AppColors.successPale
                              : AppColors.grayBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.phoneVerified
                              ? '✓ ยืนยันเบอร์โทรศัพท์แล้ว'
                              : 'ยังไม่ยืนยันเบอร์โทรศัพท์',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: user.phoneVerified
                                ? AppColors.successDark
                                : AppColors.graySecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Row (Rating, Deals, Reviews)
                if (!isGuest) ...[
                  Row(
                    children: [
                      _buildStatBox(
                        '${user.rating} ★',
                        'คะแนนความน่าเชื่อถือ',
                        AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        '${user.successfulDeals}',
                        'ทำรายการสำเร็จ',
                        AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      _buildStatBox(
                        '${user.reviewCount}',
                        'รีวิวจากผู้ใช้',
                        AppColors.oceanBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                if (isAdmin) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.dashboard_customize_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text('เข้าสู่หน้า Admin Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDashboardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Menu Options
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'ประกาศของฉัน (My Listings)',
                  subtitle: 'จัดการสินค้าที่กำลังขาย, ขายแล้ว, ซ่อน',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyListingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'ประวัติการซื้อขาย',
                  subtitle: 'ตรวจสอบสถานะออเดอร์และนัดรับ',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen(),
                      ),
                    );
                  },
                ),
                if (!isGuest) ...[
                  _buildMenuItem(
                    icon: Icons.notifications_active_outlined,
                    title: 'แจ้งเตือนในพื้นที่',
                    subtitle: 'ตั้งค่ารัศมีและหมวดหมู่ประกาศ',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AreaAlertSettingsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.block_outlined,
                    title: 'รายชื่อที่บล็อก',
                    subtitle: 'ดูและปลดบล็อกผู้ใช้',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const BlockedUsersScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.flag_outlined,
                    title: 'รายงานของฉัน',
                    subtitle: 'ติดตามสถานะการตรวจสอบรายงาน',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MyReportsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'การแจ้งเตือน',
                    subtitle: 'ดูรายการแจ้งเตือนทั้งหมด',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                ],
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: 'แนวทางซื้อขายอย่างระมัดระวัง',
                  subtitle: 'ข้อแนะนำการพูดคุย นัดรับ และชำระเงิน',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'ตรวจสอบสินค้าและนัดรับในสถานที่ที่เหมาะสม',
                        ),
                      ),
                    );
                  },
                ),
                if (kDebugMode)
                  _buildMenuItem(
                    icon: Icons.restart_alt,
                    title: 'รีเซ็ตข้อมูลตัวอย่าง (Debug)',
                    subtitle: 'ล้างข้อมูลในเครื่องและสร้างข้อมูลตัวอย่างใหม่',
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('รีเซ็ตข้อมูลตัวอย่าง?'),
                          content: const Text(
                            'ข้อมูลบัญชี ประกาศ แชท และออเดอร์ในเครื่องจะถูกล้าง',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('ยกเลิก'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('รีเซ็ต'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      final succeeded = await appState.resetSampleData();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            succeeded
                                ? 'รีเซ็ตข้อมูลตัวอย่างแล้ว'
                                : 'รีเซ็ตไม่สำเร็จ ตรวจสอบข้อผิดพลาดในโหมด debug',
                          ),
                        ),
                      );
                    },
                  ),
                _buildMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'ช่วยเหลือ & ติดต่อทีมงาน',
                  subtitle: 'FAQ และแจ้งปัญหาการใช้งาน',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ติดต่อศูนย์ช่วยเหลือ $appName')),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      appState.loginAsGuest();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SplashOnboardingScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('ออกจากระบบ (Logout)'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.grayBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grayLine),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.graySecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.aquaPale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.oceanBlue, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.graySecondary),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.graySecondary,
        ),
      ),
    );
  }
}
