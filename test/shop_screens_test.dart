import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/nearby_product.dart';
import 'package:moor_market/screens/auth/login_screen.dart';
import 'package:moor_market/screens/chat/chat_room_screen.dart';
import 'package:moor_market/screens/order/order_status_screen.dart';
import 'package:moor_market/screens/profile/public_user_profile_screen.dart';
import 'package:moor_market/screens/profile/shop_profile_screen.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/product_card.dart';

void main() {
  final appState = AppState();
  // Monday 2026-11-23 10:00 Thai time (03:00 UTC); shop_01 is open 09:00-20:00.
  DateTime openClock() => DateTime.utc(2026, 11, 23, 3);
  // 00:00 Tuesday Thai time.
  DateTime closedClock() => DateTime.utc(2026, 11, 23, 17);

  setUp(() {
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
  });

  tearDown(() {
    appState.signInVerifiedPhone('0800000011');
    final shop = appState.currentUser.shop!;
    appState.updateShopProfile(shop.copyWith(shopName: 'ร้านมือถือเจริญ'));
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
  });

  testWidgets('storefront shows name, badge, open status and listings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: ShopProfileScreen(shopUserId: 'shop_01', clock: openClock),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ร้านมือถือเจริญ'), findsWidgets);
    expect(find.text('ร้านค้า'), findsWidgets);
    expect(find.text('เปิดอยู่ · ตามเวลาที่ร้านแจ้ง'), findsOneWidget);
    expect(find.text('ทักถามร้าน'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('storefront shows closed status outside opening hours', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopProfileScreen(shopUserId: 'shop_01', clock: closedClock),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ปิดอยู่ · ตามเวลาที่ร้านแจ้ง'), findsOneWidget);
  });

  testWidgets('public profile redirects to storefront for shops', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PublicUserProfileScreen(userId: 'shop_01')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ShopProfileScreen), findsOneWidget);
  });

  testWidgets('product card shows shop badge and live shop name', (
    tester,
  ) async {
    final product = appState.products.firstWhere(
      (p) => p.sellerId == 'shop_01',
    );
    final storedName = product.sellerName;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 400,
            child: ListenableBuilder(
              listenable: appState,
              builder: (_, _) => ProductCard(
                nearbyProduct: NearbyProduct(product: product, distanceKm: 1),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('ร้านค้า'), findsOneWidget);
    expect(find.text('ร้านมือถือเจริญ'), findsOneWidget);

    appState.signInVerifiedPhone('0800000011');
    final error = appState.updateShopProfile(
      appState.currentUser.shop!.copyWith(shopName: 'ร้านชื่อใหม่'),
    );
    expect(error, isNull);
    await tester.pump();
    expect(find.text('ร้านชื่อใหม่'), findsOneWidget);
    expect(product.sellerName, storedName);
  });

  testWidgets('order status shows the shop name for a shop seller', (
    tester,
  ) async {
    final index = appState.orders.indexWhere((o) => o.id == 'ORD-2026-0901');
    final original = appState.orders[index];
    final userIndex = appState.users.indexWhere((u) => u.id == 'shop_01');
    final originalUser = appState.users[userIndex];
    appState.users[userIndex] = originalUser.copyWith(name: 'เจ้าของส่วนตัว');
    addTearDown(() => appState.users[userIndex] = originalUser);
    final owner = appState.userById('shop_01')!;
    appState.orders[index] = original.copyWith(sellerId: 'shop_01');
    addTearDown(() => appState.orders[index] = original);

    await tester.pumpWidget(
      const MaterialApp(home: OrderStatusScreen(orderId: 'ORD-2026-0901')),
    );
    await tester.pumpAndSettle();
    expect(find.text('ผู้ขาย: ${owner.shop!.shopName}'), findsOneWidget);
    expect(owner.name, isNot(owner.shop!.shopName));
    expect(find.textContaining(owner.name), findsNothing);
  });

  testWidgets('shop inquiry chat hides product quick replies and meetup tips', (
    tester,
  ) async {
    final inquiry = appState.openShopInquiry('shop_01')!;
    await tester.pumpWidget(
      MaterialApp(home: ChatRoomScreen(conversation: inquiry)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ActionChip), findsNothing);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('รายงานผู้ใช้'), findsOneWidget);
    expect(find.text('คำแนะนำก่อนนัดรับ'), findsNothing);
  });

  testWidgets('guest tapping inquiry button lands on login', (tester) async {
    appState.loginAsGuest();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopProfileScreen(shopUserId: 'shop_01', clock: openClock),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ทักถามร้าน'));
    await tester.tap(find.text('ทักถามร้าน'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('signed-in inquiry opens chat prefilled with default draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopProfileScreen(shopUserId: 'shop_01', clock: openClock),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ทักถามร้าน'));
    await tester.tap(find.text('ทักถามร้าน'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatRoomScreen), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'สวัสดีครับ สอบถามสินค้าหน่อยครับ');
  });
}
