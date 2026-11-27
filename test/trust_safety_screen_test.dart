import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/screens/admin/admin_dashboard_screen.dart';
import 'package:moor_market/screens/profile/area_alert_settings_screen.dart';
import 'package:moor_market/screens/profile/public_user_profile_screen.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();
  late List<UserModel> originalUsers;

  setUp(() {
    originalUsers = List<UserModel>.of(appState.users);
  });

  tearDown(() {
    appState.users = originalUsers;
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    appState.updateAreaAlertSubscription(
      enabled: true,
      radiusKm: 5,
      categories: const [],
    );
  });

  testWidgets('member opening admin dashboard is redirected with a message', (
    tester,
  ) async {
    appState.currentUser = appState.userById('user_01')!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AdminDashboardScreen(),
                ),
              ),
              child: const Text('open admin'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open admin'));
    await tester.pumpAndSettle();
    expect(find.text('open admin'), findsOneWidget);
    expect(find.text('เฉพาะผู้ดูแลระบบเท่านั้น'), findsOneWidget);
  });

  testWidgets('admin dashboard metrics use current AppState values', (
    tester,
  ) async {
    appState.currentUser = appState.userById('admin_01')!;
    await tester.pumpWidget(const MaterialApp(home: AdminDashboardScreen()));
    await tester.pumpAndSettle();
    expect(find.text('ผู้ใช้'), findsOneWidget);
    expect(find.text('${appState.users.length}'), findsAtLeastNWidgets(1));
    expect(find.text('${appState.pendingOrderCount}'), findsAtLeastNWidgets(1));
    expect(
      find.text('${appState.completedOrderCount}'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets(
    'area alert settings save the selected radius and enabled state',
    (tester) async {
      appState.currentUser = appState.userById('user_01')!;
      await tester.pumpWidget(
        const MaterialApp(home: AreaAlertSettingsScreen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.drag(find.byType(Slider), const Offset(130, 0));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(find.text('บันทึกการตั้งค่า'));
      await tester.pumpAndSettle();
      final subscription = appState.areaAlertSubscriptionFor('user_01');
      expect(subscription.enabled, isFalse);
      expect(subscription.radiusKm, greaterThan(5));
    },
  );

  testWidgets('public profile hides phone and area and exposes trust details', (
    tester,
  ) async {
    final user = UserModel(
      id: 'public_test_user',
      name: 'ผู้ใช้ทดสอบ',
      phone: '0991234567',
      phoneVerified: true,
      homeLabel: 'ที่อยู่ส่วนตัว',
      successfulDeals: 3,
      rating: 4.5,
      reviewCount: 2,
    );
    appState.users = [...appState.users, user];
    appState.currentUser = appState.userById('user_01')!;
    await tester.pumpWidget(
      const MaterialApp(
        home: PublicUserProfileScreen(userId: 'public_test_user'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ผู้ใช้ทดสอบ'), findsOneWidget);
    expect(find.text('ยืนยันเบอร์โทรศัพท์แล้ว'), findsOneWidget);
    expect(find.text('3 รายการสำเร็จ'), findsOneWidget);
    expect(find.text('0991234567'), findsNothing);
    expect(find.text('ที่อยู่ส่วนตัว'), findsNothing);
  });
}
