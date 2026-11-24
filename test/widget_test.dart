import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/main.dart';

void main() {
  testWidgets('app opens with community branding', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DolpApp());

    expect(find.text(appName), findsWidgets);
    expect(find.text('เข้าชมแบบ Guest >'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับสู่ dolp'), findsOneWidget);
    expect(find.text('เริ่มต้นใช้งาน / สมัครสมาชิก'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ (Login)'), findsOneWidget);
  });
}
