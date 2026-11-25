import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/screens/auth/splash_onboarding_screen.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/onboarding_visuals.dart';

Future<void> _pumpScreen(
  WidgetTester tester,
  Size size, {
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: const SplashOnboardingScreen(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // Seed data signs in user_01 until initialize() runs; onboarding only
  // stays visible for a guest.
  setUp(() => AppState().loginAsGuest());

  testWidgets('no overflow at 320x568 scale 1.3', (tester) async {
    await _pumpScreen(tester, const Size(320, 568), textScale: 1.3);
    for (var page = 0; page < 3; page++) {
      expect(tester.takeException(), isNull, reason: 'page $page');
      expect(find.byType(OnboardingVisual), findsOneWidget);
      if (page < 2) {
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();
      }
    }
  });

  testWidgets('visual caps at 360 on 430x932', (tester) async {
    await _pumpScreen(tester, const Size(430, 932));
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(OnboardingVisual));
    expect(size.height, lessThanOrEqualTo(360));
    expect(size.height, greaterThanOrEqualTo(220));
    expect(size.width, lessThanOrEqualTo(440));
  });

  testWidgets('swipe over visual changes page', (tester) async {
    await _pumpScreen(tester, const Size(360, 780));
    await tester.drag(find.byType(OnboardingVisual), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.text('ค้นหาสิ่งของใกล้ตัว'), findsOneWidget);
  });
}
