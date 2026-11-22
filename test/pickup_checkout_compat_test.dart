import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/screens/order/pickup_point_screen.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  testWidgets('legacy pickup selection still opens its payment step', (
    tester,
  ) async {
    final product = AppState().products.first;
    await tester.pumpWidget(
      MaterialApp(home: PickupPointScreen(product: product)),
    );
    await tester.pumpAndSettle();

    expect(find.text('เลือกจุดนัดรับ'), findsOneWidget);
    await tester.ensureVisible(find.text('ถัดไป: สรุปการชำระเงิน'));
    await tester.tap(find.text('ถัดไป: สรุปการชำระเงิน'));
    await tester.pumpAndSettle();

    expect(find.text('ชำระเงิน & พักเงิน (Escrow)'), findsOneWidget);
    expect(find.textContaining('เขตเมือง'), findsNothing);
  });
}
