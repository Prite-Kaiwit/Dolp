import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/screens/auth/login_screen.dart';
import 'package:moor_market/screens/auth/phone_otp_screen.dart';
import 'package:moor_market/screens/auth/sign_up_screen.dart';

void main() {
  testWidgets('sign-up remains disabled until required fields are valid', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    final signUpButton = find.widgetWithText(
      ElevatedButton,
      'ลงทะเบียนและรับรหัส OTP',
    );
    expect(tester.widget<ElevatedButton>(signUpButton).onPressed, isNull);

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2), reason: 'name and phone only');
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'ผู้ใช้ทดสอบ');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), '0897654321');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(signUpButton).onPressed, isNotNull);
  });

  testWidgets('login asks for a phone number only', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('ขอรหัส OTP'), findsOneWidget);
    expect(find.text('รหัสผ่าน'), findsNothing);
  });

  testWidgets('OTP screen rejects an incorrect code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhoneOtpScreen(name: 'ผู้ใช้ทดสอบ', phone: '0897654321'),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextField).at(i), '0');
    }
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(
      find.text('รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง'),
      findsOneWidget,
    );
  });
}
