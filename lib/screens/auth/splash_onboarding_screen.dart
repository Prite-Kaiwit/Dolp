import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';
import '../main_navigation_screen.dart';
import '../../state/app_state.dart';

class SplashOnboardingScreen extends StatefulWidget {
  const SplashOnboardingScreen({super.key});

  @override
  State<SplashOnboardingScreen> createState() => _SplashOnboardingScreenState();
}

class _SplashOnboardingScreenState extends State<SplashOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'ยินดีต้อนรับสู่ มอ.มาร์เก็ต',
      'subtitle': 'MoorMarket (MOU Market)',
      'desc': 'แพลตฟอร์มตลาดออนไลน์ของชาวมหาวิทยาลัย ซื้อ-ขาย-แลกเปลี่ยน-บริจาค สินค้าอย่างมั่นใจในสังคมเดียวกัน',
      'icon': '🏫',
      'badge': 'สังคมมหาวิทยาลัยที่ไว้ใจได้',
    },
    {
      'title': 'ปลอดภัยด้วยระบบพักเงิน Escrow',
      'subtitle': 'ช้อปสบายใจ ไร้กังวลเรื่องโดนโกง',
      'desc': 'เงินจะถูกพักไว้อย่างปลอดภัยในระบบ และจะโอนให้ผู้ขายเมื่อผู้ซื้อตรวจสอบและกดยืนยันรับสินค้าแล้วเท่านั้น',
      'icon': '🔒',
      'badge': 'Escrow Protected 100%',
    },
    {
      'title': 'ส่งมอบสะดวก ณ จุดนัดรับใน มอ.',
      'subtitle': 'Campus Pickup Points',
      'desc': 'เลือกจุดนัดรับที่สะดวก เช่น โรงอาหารกลาง หอสมุด ลานกิจกรรม ตรวจสอบสินค้าจริงก่อนยืนยันรับ',
      'icon': '📍',
      'badge': 'จุดนัดรับปลอดภัยภายในมหาวิทยาลัย',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip & Guest Entry
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Logo & Brand
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pinkPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🛍️', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 8),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'มอ.Market',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pinkPrimary,
                            ),
                          ),
                          Text(
                            'MOU Market v1.0',
                            style: TextStyle(fontSize: 11, color: AppColors.graySecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      AppState().loginAsGuest();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                      );
                    },
                    child: const Text(
                      'เข้าชมแบบ Guest >',
                      style: TextStyle(
                        color: AppColors.graySecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final item = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large Graphic Icon Container
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: index % 2 == 0 ? AppColors.pinkPale : AppColors.greenPale,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: index % 2 == 0 ? AppColors.pinkLight : AppColors.greenLight,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item['icon']!,
                              style: const TextStyle(fontSize: 76),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: index % 2 == 0 ? AppColors.pinkPale : AppColors.greenPale,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['badge']!,
                            style: TextStyle(
                              color: index % 2 == 0 ? AppColors.pinkDark : AppColors.greenDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.inkText,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          item['subtitle']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: index % 2 == 0 ? AppColors.pinkPrimary : AppColors.greenDark,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Desc
                        Text(
                          item['desc']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.graySecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.pinkPrimary : AppColors.grayLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pinkPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'เริ่มต้นใช้งาน / สมัครสมาชิก',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.pinkPrimary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'เข้าสู่ระบบ (Login)',
                        style: TextStyle(
                          color: AppColors.pinkPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
