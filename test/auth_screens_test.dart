import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/shop_profile.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/screens/auth/login_screen.dart';
import 'package:moor_market/screens/auth/phone_otp_screen.dart';
import 'package:moor_market/screens/auth/shop_setup_screen.dart';
import 'package:moor_market/screens/auth/sign_up_screen.dart';
import 'package:moor_market/screens/profile/profile_screen.dart';
import 'package:moor_market/state/app_state.dart';

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

  testWidgets(
    'sign-up shows account type choice and shop path goes to shop setup',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

      expect(find.text('บุคคลทั่วไป'), findsOneWidget);
      expect(find.text('ร้านค้า'), findsOneWidget);
      expect(find.text('ลงทะเบียนและรับรหัส OTP'), findsOneWidget);

      await tester.tap(find.text('ร้านค้า'));
      await tester.pump();
      expect(find.text('ลงทะเบียนและรับรหัส OTP'), findsNothing);

      final next = find.widgetWithText(ElevatedButton, 'ถัดไป: ตั้งค่าร้าน');
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'เจ้าของร้าน');
      await tester.enterText(fields.at(1), '0897654322');
      await tester.ensureVisible(find.byType(Checkbox));
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();

      expect(find.byType(ShopSetupScreen), findsOneWidget);
    },
  );

  testWidgets(
    'shop setup submit stays disabled until name, category, location label and hours are set',
    (tester) async {
      ShopProfile? submitted;
      await tester.pumpWidget(
        MaterialApp(
          home: ShopSetupScreen(
            mode: ShopSetupMode.register,
            initial: ShopProfile(
              shopName: '',
              location: GeoLocation(12.61, 102.10),
              locationLabel: 'ท่าช้าง',
            ),
            onSubmitted: (profile) => submitted = profile,
          ),
        ),
      );

      final submit = find.byKey(const ValueKey('shop-setup-submit'));
      bool enabled() => tester.widget<ElevatedButton>(submit).onPressed != null;

      expect(enabled(), isFalse);
      await tester.enterText(
        find.byKey(const ValueKey('shop-name')),
        'ร้านทดสอบ',
      );
      await tester.pump();
      expect(enabled(), isFalse);

      final chip = find.widgetWithText(FilterChip, 'หนังสือ');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pump();
      expect(enabled(), isFalse, reason: 'hours still missing');

      final monday = find.byKey(const ValueKey('hours-switch-1'));
      await tester.ensureVisible(monday);
      await tester.tap(monday);
      await tester.pump();
      expect(enabled(), isTrue);

      await tester.tap(monday);
      await tester.pump();
      expect(enabled(), isFalse);
      await tester.tap(monday);
      await tester.pump();

      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(submitted?.shopName, 'ร้านทดสอบ');
      expect(submitted?.categories, ['หนังสือ']);
      expect(submitted?.openingHours.days.keys, [1]);
    },
  );

  group('profile account tiles', () {
    final appState = AppState();
    late UserModel original;
    setUp(() => original = appState.currentUser);
    tearDown(() => appState.currentUser = original);

    testWidgets(
      'profile shows convert tile for person and edit tile for shop',
      (tester) async {
        appState.currentUser = UserModel(
          id: 'person_tile',
          name: 'คนทั่วไป',
          avatarUrl: '',
        );
        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        expect(find.text('เปลี่ยนเป็นร้านค้า'), findsOneWidget);
        expect(find.text('แก้ไขข้อมูลร้าน'), findsNothing);

        appState.currentUser = UserModel(
          id: 'shop_tile',
          name: 'เจ้าของ',
          avatarUrl: '',
          accountType: AccountType.shop,
          shop: ShopProfile(
            shopName: 'ร้านตัวอย่าง',
            categories: const ['หนังสือ'],
            location: GeoLocation(12.61, 102.10),
            locationLabel: 'ท่าช้าง',
            openingHours: const OpeningHours(
              days: {1: DayHours(openMinute: 540, closeMinute: 1080)},
            ),
          ),
        );
        await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
        await tester.pump();
        expect(find.text('เปลี่ยนเป็นร้านค้า'), findsNothing);
        expect(
          find.text('แก้ไขข้อมูลร้าน', skipOffstage: false),
          findsOneWidget,
        );
        expect(find.text('ร้านตัวอย่าง'), findsOneWidget);
      },
    );
  });
}
