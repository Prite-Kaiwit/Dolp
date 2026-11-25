import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/onboarding_visuals.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 340, height: 300, child: child)),
  ),
);

void main() {
  final appState = AppState();
  final products = appState.products
      .where((p) => p.status == ListingStatus.active)
      .take(3)
      .toList();
  final spot = appState.pickupPoints.first;

  for (var page = 0; page < 3; page++) {
    testWidgets('renders page $page with 3 products', (tester) async {
      await tester.pumpWidget(
        _host(OnboardingVisual(page: page, products: products, spot: spot)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(MapPin), findsWidgets);
      if (page == 1) expect(find.text('3 กม.'), findsOneWidget);
      if (page == 2) expect(find.text('ยอมรับแล้ว'), findsOneWidget);
    });
  }

  testWidgets('renders with no products', (tester) async {
    for (var page = 0; page < 3; page++) {
      await tester.pumpWidget(
        _host(OnboardingVisual(page: page, products: const [])),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
    }
  });
}
