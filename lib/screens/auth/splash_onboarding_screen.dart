import 'package:flutter/material.dart';
import '../../constants/app_info.dart';
import '../../theme/app_theme.dart';
import '../../models/pickup_point.dart';
import '../../models/product.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/onboarding_visuals.dart';
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

  late final List<ProductModel> _visualProducts = AppState().products
      .where((product) => product.status == ListingStatus.active)
      .take(3)
      .toList();
  late final SuggestedSpot? _visualSpot = AppState().pickupPoints.isEmpty
      ? null
      : AppState().pickupPoints.first;

  /// 46% of the screen height, clamped to 220–360, then shrunk if needed so
  /// the copy below stays on screen. The copy wins on short screens; the
  /// visual never drops below 140.
  static double _visualHeight({
    required double screenHeight,
    required double available,
    required bool isShort,
    required double textScale,
  }) {
    const floor = 140.0;
    final target = (screenHeight * 0.46).clamp(220.0, 360.0);
    final copyReserve = (isShort ? 170.0 : 210.0) * textScale.clamp(1.0, 2.0);
    final room = available - copyReserve;
    return room < target ? room.clamp(floor, target) : target;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = AppState();
      if (appState.isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
        );
        return;
      }
      final warning = appState.takePersistenceWarning();
      if (warning != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(warning)));
      }
    });
  }

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'ยินดีต้อนรับสู่ $appName',
      'subtitle': 'ตลาดชุมชนใกล้บ้าน',
      'desc':
          'เลือกพื้นที่ใกล้คุณ พบสินค้าที่ต้องการ และซื้อขายแลกเปลี่ยนกับคนในชุมชน',
      'badge': 'ตลาดชุมชนใกล้บ้าน',
    },
    {
      'title': 'ค้นหาสิ่งของใกล้ตัว',
      'subtitle': 'นัดรับตามที่ตกลงกัน',
      'desc':
          'เลือกสินค้าตามระยะที่คุณต้องการ พูดคุยกับผู้ขาย แล้วนัดรับในสถานที่สะดวก',
      'badge': 'ตลาดของคนใกล้บ้าน',
    },
    {
      'title': 'ซื้อขายอย่างระมัดระวัง',
      'subtitle': 'พูดคุยและตกลงรายละเอียดก่อนนัดรับ',
      'desc':
          'ตรวจสอบสินค้า นัดพบในสถานที่ปลอดภัย และเลือกวิธีชำระเงินที่ตกลงร่วมกัน',
      'badge': 'ใส่ใจทุกขั้นตอน',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header inspired by the community-app prototype
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showTagline = constraints.maxWidth >= 360;
                  return Row(
                    children: [
                      const BrandLogo(size: 50),
                      if (showTagline) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 38,
                          color: AppColors.grayLine,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            appTagline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.deepNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else
                        const Spacer(),
                      Flexible(
                        child: TextButton(
                          onPressed: () {
                            AppState().loginAsGuest();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigationScreen(),
                              ),
                            );
                          },
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'เข้าชมแบบ Guest >',
                              maxLines: 1,
                              style: TextStyle(
                                color: AppColors.oceanBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
                  final screenHeight = MediaQuery.sizeOf(context).height;
                  final isShort = screenHeight < 640;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final visualHeight = _visualHeight(
                        screenHeight: screenHeight,
                        available: constraints.maxHeight,
                        isShort: isShort,
                        textScale: MediaQuery.textScalerOf(context).scale(1),
                      );
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 440,
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: visualHeight,
                                  child: OnboardingVisual(
                                    page: index,
                                    products: _visualProducts,
                                    spot: _visualSpot,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isShort ? 14 : 20),

                            // Badge (dropped on short screens to keep the
                            // copy visible)
                            if (!isShort) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.aquaPale,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item['badge']!,
                                  style: TextStyle(
                                    color: AppColors.deepNavy,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Title
                            Text(
                              item['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              item['subtitle']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.oceanBlue,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Desc
                            Text(
                              item['desc']!,
                              textAlign: TextAlign.center,
                              maxLines: isShort ? 3 : null,
                              overflow: isShort ? TextOverflow.ellipsis : null,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.graySecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      );
                    },
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
                    color: _currentPage == index
                        ? AppColors.oceanBlue
                        : AppColors.grayLine,
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
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.oceanBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'เริ่มต้นใช้งาน / สมัครสมาชิก',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.oceanBlue,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'เข้าสู่ระบบ (Login)',
                        style: TextStyle(
                          color: AppColors.oceanBlue,
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
