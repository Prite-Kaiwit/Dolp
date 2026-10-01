import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/main.dart';

void main() {
  testWidgets('MoorMarketApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MoorMarketApp());

    // Verify that MoorMarket brand text is rendered
    expect(find.text('มอ.Market'), findsWidgets);
    expect(find.text('เข้าชมแบบ Guest >'), findsOneWidget);
  });
}
