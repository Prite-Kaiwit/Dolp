import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'ผู้ใช้ทดสอบ');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), '0897654321');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'password123');
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'password123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(tester.widget<ElevatedButton>(signUpButton).onPressed, isNotNull);
  });

  testWidgets('OTP screen rejects an incorrect code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PhoneOtpScreen(
          name: 'ผู้ใช้ทดสอบ',
          phone: '0897654321',
          password: 'password123',
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, '0');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(
      find.text('รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง'),
      findsOneWidget,
    );
  });
}
