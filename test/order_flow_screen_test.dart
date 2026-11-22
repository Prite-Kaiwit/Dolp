import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/order.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/screens/order/cart_screen.dart';
import 'package:moor_market/screens/order/order_history_screen.dart';
import 'package:moor_market/screens/order/order_status_screen.dart';
import 'package:moor_market/screens/order/order_summary_screen.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();
  late List<ProductModel> originalProducts;
  late List<ProductModel> originalCart;
  late List<OrderModel> originalOrders;

  setUp(() {
    originalProducts = List<ProductModel>.of(appState.products);
    originalCart = List<ProductModel>.of(appState.cartItems);
    originalOrders = List<OrderModel>.of(appState.orders);
    appState.cartItems.clear();
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    final product = appState.products.firstWhere((item) => item.id == 'prod_6');
    expect(appState.addToCart(product), isNull);
  });

  tearDown(() {
    final oldIds = originalOrders.map((order) => order.id).toSet();
    for (final order in List<OrderModel>.of(appState.orders)) {
      if (!oldIds.contains(order.id)) {
        appState.cancelOrder(order.id, 'cleanup');
      }
    }
    appState.products = originalProducts;
    appState.cartItems = originalCart;
    appState.orders = originalOrders;
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
  });

  testWidgets('summary requires handover payment and creates a reserved order', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OrderSummaryScreen(sellerId: 'user_07'),
      ),
    );

    expect(find.text('โอนตอนรับของ'), findsOneWidget);
    expect(find.text('ตรวจสินค้าก่อนจ่ายเงิน ไม่โอนก่อนเห็นของถ้าไม่มั่นใจ'), findsOneWidget);

    final confirm = find.text('ยืนยันคำสั่งซื้อ');
    expect(tester.widget<ElevatedButton>(find.ancestor(
      of: confirm,
      matching: find.byType(ElevatedButton),
    )).onPressed, isNull);

    await tester.tap(find.text('เงินสดหน้างาน'));
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    final order = appState.orders.first;
    expect(order.status.name, 'pending');
    expect(order.sellerId, 'user_07');
    expect(appState.products.firstWhere((item) => item.id == 'prod_6').status,
        ListingStatus.reserved);
    expect(appState.cartItems, isEmpty);
    expect(find.text('สถานะคำสั่งซื้อ'), findsOneWidget);
  });

  testWidgets('cart groups sellers and warns that pickup is separate', (
    tester,
  ) async {
    appState.clearCart();
    for (final id in ['prod_2', 'prod_7', 'prod_4']) {
      expect(
        appState.addToCart(appState.products.firstWhere((item) => item.id == id)),
        isNull,
      );
    }

    await tester.pumpWidget(const MaterialApp(home: CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('สินค้าอยู่คนละที่ ต้องนัดรับแยกกัน'), findsOneWidget);
    expect(find.text('ตกลงซื้อกับผู้ขายนี้'), findsNWidgets(2));
    expect(find.text('ยอดรวมในตะกร้า'), findsOneWidget);
  });

  testWidgets('status actions follow buyer and seller roles', (tester) async {
    expect(appState.currentUser.id, 'user_01');
    expect(
      appState.orders
          .firstWhere((order) => order.id == 'ORD-2026-0901')
          .status,
      OrderStatus.pending,
    );
    expect(
      appState.orders
          .firstWhere((order) => order.id == 'ORD-2026-0901')
          .buyerId,
      appState.currentUser.id,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: OrderStatusScreen(orderId: 'ORD-2026-0901'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ได้รับสินค้าแล้ว'), 300);
    await tester.pumpAndSettle();
    expect(find.text('ได้รับสินค้าแล้ว'), findsOneWidget);
    expect(find.text('รายงานปัญหา'), findsOneWidget);
    expect(find.text('ยืนยันส่งมอบ'), findsNothing);

    appState.currentUser = appState.userById('user_02')!;
    await tester.pumpWidget(
      const MaterialApp(
        home: OrderStatusScreen(orderId: 'ORD-2026-0901'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ยืนยันส่งมอบ'), 300);
    await tester.pumpAndSettle();
    expect(find.text('ยืนยันส่งมอบ'), findsOneWidget);
    expect(find.text('ได้รับสินค้าแล้ว'), findsNothing);
    expect(find.text('รายงานปัญหา'), findsNothing);
  });

  testWidgets('history tabs count the current buyer orders', (tester) async {
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
    await tester.pumpWidget(const MaterialApp(home: OrderHistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ทั้งหมด (3)'), findsOneWidget);
    expect(find.text('รอนัดรับ (1)'), findsOneWidget);
    expect(find.text('สำเร็จ (1)'), findsOneWidget);
    expect(find.text('ยกเลิก-มีปัญหา (1)'), findsOneWidget);
  });
}
