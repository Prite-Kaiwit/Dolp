import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/widgets/brand_logo.dart';

void main() {
  testWidgets('BrandLogo shows the app name fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandLogo())),
    );

    expect(find.text(appName), findsOneWidget);
  });

  testWidgets('BrandLogo can render a supplied image logo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrandLogo(
            logoImage: Image.asset(
              'test-logo.png',
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text(appName), findsNothing);
  });
}
