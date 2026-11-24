import 'package:flutter/material.dart';
import '../../constants/app_info.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
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
                      TextButton(
                        onPressed: () {
                          AppState().loginAsGuest();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'เข้าชมแบบ Guest >',
                          style: TextStyle(
                            color: AppColors.oceanBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 170,
                          child: CustomPaint(
                            painter: _OnboardingPainter(index),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Badge
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

                        // Title
                        Text(
                          item['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepNavy,
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
                            color: AppColors.oceanBlue,
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
                    height: 50,
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
                    height: 50,
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

class _OnboardingPainter extends CustomPainter {
  const _OnboardingPainter(this.pageIndex);

  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.54);
    final paleBlue = Paint()..color = AppColors.aquaPale;
    final blue = Paint()..color = AppColors.oceanBlue;
    final green = Paint()..color = AppColors.successLight;
    final greenDark = Paint()..color = AppColors.success;
    final navy = Paint()
      ..color = AppColors.deepNavy
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final blob = Path()
      ..moveTo(size.width * 0.08, size.height * 0.58)
      ..cubicTo(
        size.width * 0.01,
        size.height * 0.28,
        size.width * 0.22,
        size.height * 0.17,
        size.width * 0.42,
        size.height * 0.25,
      )
      ..cubicTo(
        size.width * 0.63,
        size.height * 0.34,
        size.width * 0.71,
        size.height * 0.05,
        size.width * 0.91,
        size.height * 0.24,
      )
      ..cubicTo(
        size.width * 1.02,
        size.height * 0.43,
        size.width * 0.88,
        size.height * 0.72,
        size.width * 0.72,
        size.height * 0.78,
      )
      ..cubicTo(
        size.width * 0.48,
        size.height * 0.88,
        size.width * 0.24,
        size.height * 0.78,
        size.width * 0.08,
        size.height * 0.58,
      )
      ..close();
    canvas.drawPath(blob, paleBlue);

    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.82),
      Offset(size.width * 0.92, size.height * 0.82),
      navy..strokeWidth = 4,
    );

    if (pageIndex == 0) {
      _drawHouse(canvas, center, size, blue, green, greenDark, navy);
    } else if (pageIndex == 1) {
      _drawMap(canvas, center, size, blue, green, greenDark);
    } else {
      _drawHandshake(canvas, center, size, blue, green, greenDark);
    }
  }

  void _drawHouse(
    Canvas canvas,
    Offset center,
    Size size,
    Paint blue,
    Paint green,
    Paint greenDark,
    Paint navy,
  ) {
    final orange = Paint()..color = const Color(0xFFFF8A4C);
    final wall = Paint()..color = AppColors.white;
    final houseRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.59),
      width: size.width * 0.48,
      height: size.height * 0.38,
    );
    canvas.drawRect(houseRect, wall);

    final roof = Path()
      ..moveTo(size.width * 0.21, size.height * 0.42)
      ..lineTo(size.width * 0.50, size.height * 0.22)
      ..lineTo(size.width * 0.79, size.height * 0.42)
      ..lineTo(size.width * 0.74, size.height * 0.49)
      ..lineTo(size.width * 0.50, size.height * 0.31)
      ..lineTo(size.width * 0.26, size.height * 0.49)
      ..close();
    canvas.drawPath(roof, orange);

    final doorRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.68),
      width: size.width * 0.12,
      height: size.height * 0.22,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(doorRect, const Radius.circular(5)),
      blue,
    );
    canvas.drawCircle(
      Offset(center.dx - size.width * 0.026, size.height * 0.68),
      3,
      Paint()..color = AppColors.white,
    );
    canvas.drawCircle(
      Offset(center.dx + size.width * 0.026, size.height * 0.68),
      3,
      Paint()..color = AppColors.white,
    );

    for (final x in [0.28, 0.66]) {
      final windowRect = Rect.fromLTWH(
        size.width * x,
        size.height * 0.55,
        size.width * 0.10,
        size.height * 0.13,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(windowRect, const Radius.circular(4)),
        Paint()..color = AppColors.aqua,
      );
    }

    canvas.drawCircle(
      Offset(size.width * 0.11, size.height * 0.69),
      size.height * 0.07,
      green,
    );
    canvas.drawCircle(
      Offset(size.width * 0.89, size.height * 0.69),
      size.height * 0.07,
      green,
    );
    canvas.drawLine(
      Offset(size.width * 0.11, size.height * 0.69),
      Offset(size.width * 0.11, size.height * 0.82),
      navy..strokeWidth = 4,
    );
    canvas.drawLine(
      Offset(size.width * 0.89, size.height * 0.69),
      Offset(size.width * 0.89, size.height * 0.82),
      navy..strokeWidth = 4,
    );
  }

  void _drawMap(
    Canvas canvas,
    Offset center,
    Size size,
    Paint blue,
    Paint green,
    Paint greenDark,
  ) {
    final map = Paint()..color = AppColors.white;
    final mapRect = Rect.fromCenter(
      center: Offset(center.dx, size.height * 0.58),
      width: size.width * 0.64,
      height: size.height * 0.30,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(mapRect, const Radius.circular(12)),
      map,
    );
    final road = Paint()
      ..color = AppColors.aqua
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.66)
      ..lineTo(size.width * 0.40, size.height * 0.56)
      ..lineTo(size.width * 0.55, size.height * 0.67)
      ..lineTo(size.width * 0.78, size.height * 0.52);
    canvas.drawPath(path, road);

    final pin = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(
      Offset(center.dx, size.height * 0.48),
      size.height * 0.07,
      pin,
    );
    final pinPath = Path()
      ..moveTo(center.dx - size.width * 0.06, size.height * 0.48)
      ..lineTo(center.dx, size.height * 0.70)
      ..lineTo(center.dx + size.width * 0.06, size.height * 0.48)
      ..close();
    canvas.drawPath(pinPath, pin);
    canvas.drawCircle(
      Offset(center.dx, size.height * 0.47),
      size.height * 0.025,
      Paint()..color = AppColors.white,
    );

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.68),
      size.height * 0.055,
      green,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.68),
      size.height * 0.055,
      green,
    );
  }

  void _drawHandshake(
    Canvas canvas,
    Offset center,
    Size size,
    Paint blue,
    Paint green,
    Paint greenDark,
  ) {
    final orange = Paint()..color = const Color(0xFFFFB07C);
    final darkBlue = Paint()..color = const Color(0xFF2057A3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.17,
          size.height * 0.46,
          size.width * 0.20,
          size.height * 0.12,
        ),
        const Radius.circular(8),
      ),
      blue,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.63,
          size.height * 0.46,
          size.width * 0.20,
          size.height * 0.12,
        ),
        const Radius.circular(8),
      ),
      darkBlue,
    );

    final hand = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, size.height * 0.58),
        width: size.width * 0.42,
        height: size.height * 0.13,
      ),
      const Radius.circular(20),
    );
    canvas.drawRRect(hand, orange);
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.58),
      Offset(size.width * 0.66, size.height * 0.58),
      Paint()
        ..color = const Color(0xFFEF8A58)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.68),
      size.height * 0.055,
      green,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.68),
      size.height * 0.055,
      green,
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingPainter oldDelegate) =>
      oldDelegate.pageIndex != pageIndex;
}
