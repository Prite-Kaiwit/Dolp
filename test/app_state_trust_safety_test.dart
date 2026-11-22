import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/models/area_alert_subscription.dart';
import 'package:moor_market/models/chat.dart';
import 'package:moor_market/models/notification.dart';
import 'package:moor_market/models/order.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/report.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/utils/meetup_sharing.dart';

void main() {
  final appState = AppState();
  late List<UserModel> originalUsers;
  late List<ProductModel> originalProducts;
  late List<ProductModel> originalCart;
  late List<OrderModel> originalOrders;
  late List<ReportModel> originalReports;
  late List<AppNotification> originalNotifications;
  late List<ChatConversation> originalConversations;
  late Map<String, AreaAlertSubscription> originalSubscriptions;

  setUp(() {
    originalUsers = List<UserModel>.of(appState.users);
    originalProducts = List<ProductModel>.of(appState.products);
    originalCart = List<ProductModel>.of(appState.cartItems);
    originalOrders = List<OrderModel>.of(appState.orders);
    originalReports = List<ReportModel>.of(appState.reports);
    originalNotifications = List<AppNotification>.of(appState.notifications);
    originalConversations = List<ChatConversation>.of(appState.conversations);
    originalSubscriptions = {
      for (final user in appState.users)
        user.id: appState.areaAlertSubscriptionFor(user.id),
    };
    appState.currentUser = appState.userById('user_01')!;
    appState.cartItems.clear();
    appState.setClockForTesting(DateTime.now);
  });

  tearDown(() {
    final oldOrderIds = originalOrders.map((order) => order.id).toSet();
    for (final order in List<OrderModel>.of(appState.orders)) {
      if (oldOrderIds.contains(order.id)) continue;
      if (order.status == OrderStatus.disputed) {
        appState.currentUser = appState.userById('admin_01')!;
        final report = appState.reports
            .where((item) => item.orderId == order.id)
            .firstOrNull;
        if (report != null) {
          appState.resolveReport(
            report.id,
            action: AdminReportAction.dismiss,
            adminNote: '',
          );
        }
      }
      final current = appState.orders
          .where((item) => item.id == order.id)
          .firstOrNull;
      if (current?.status == OrderStatus.pending) {
        appState.currentUser = appState.userById(current!.buyerId)!;
        appState.cancelOrder(order.id, 'test cleanup');
      }
    }
    appState.users = originalUsers;
    appState.products = originalProducts;
    appState.cartItems = originalCart;
    appState.orders = originalOrders;
    appState.reports = originalReports;
    appState.notifications = originalNotifications;
    appState.conversations = originalConversations;
    appState.setClockForTesting(DateTime.now);
    appState.currentUser = appState.userById('user_01')!;
    appState.unblockUser('user_03');
    appState.unblockUser('user_04');
    for (final subscription in originalSubscriptions.values) {
      appState.currentUser = appState.userById(subscription.userId)!;
      appState.updateAreaAlertSubscription(
        enabled: subscription.enabled,
        radiusKm: subscription.radiusKm,
        categories: subscription.categories,
      );
    }
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
  });

  test('blocking works both ways, filters products, and can be undone', () {
    expect(appState.addToCart(productById(appState, 'prod_2')), isNull);
    final conversation = appState.conversations.firstWhere(
      (item) => item.productId == 'prod_2',
    );
    expect(appState.blockUser('user_03'), isNull);
    expect(appState.isBlocked('user_03'), isTrue);
    expect(
      appState.productsNearby(radiusKm: 100).map((item) => item.product.id),
      isNot(contains('prod_2')),
    );
    expect(
      appState.addToCart(productById(appState, 'prod_2')),
      contains('บล็อกกัน'),
    );
    expect(
      appState.sendTextMessage(conversation.id, 'ทดสอบ'),
      contains('บล็อกกัน'),
    );
    expect(
      appState.proposeMeetup(
        conversationId: conversation.id,
        pickupType: PickupType.sellerHome,
        placeLabel: '',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      ),
      contains('บล็อกกัน'),
    );
    expect(
      appState
          .createOrderForSeller(
            'user_03',
            paymentMethod: PaymentMethod.cashOnHandover,
          )
          .error,
      contains('บล็อกกัน'),
    );

    appState.currentUser = appState.userById('user_03')!;
    expect(appState.isBlocked('user_01'), isTrue);
    expect(appState.unblockUser('user_01'), isNull);
    appState.currentUser = appState.userById('user_01')!;
    expect(appState.addToCart(productById(appState, 'prod_2')), isNull);
    expect(
      appState.productsNearby(radiusKm: 100).map((item) => item.product.id),
      contains('prod_2'),
    );
  });

  test('reports validate callers, detail, target, and open duplicates', () {
    appState.loginAsGuest();
    expect(
      appState.submitReport(
        reportedUserId: 'user_03',
        reason: ReportReason.other,
        detail: 'รายละเอียด',
      ),
      contains('เข้าสู่ระบบ'),
    );

    appState.currentUser = appState.userById('user_01')!;
    expect(
      appState.submitReport(
        reportedUserId: 'user_01',
        reason: ReportReason.other,
        detail: 'รายละเอียด',
      ),
      contains('ตัวเอง'),
    );
    expect(
      appState.submitReport(
        reportedUserId: 'user_03',
        reason: ReportReason.other,
        detail: '   ',
      ),
      contains('รายละเอียด'),
    );
    expect(
      appState.submitReport(
        reportedUserId: 'user_03',
        reason: ReportReason.other,
        detail: 'x' * 1001,
      ),
      contains('1000'),
    );
    expect(
      appState.submitReport(
        reportedUserId: 'user_02',
        productId: 'prod_2',
        reason: ReportReason.other,
        detail: 'ข้อมูล',
      ),
      contains('ไม่ตรง'),
    );

    expect(
      appState.submitReport(
        reportedUserId: 'user_03',
        orderId: 'ORD-2026-0808',
        productId: 'prod_2',
        reason: ReportReason.paymentScam,
        detail: 'ขอให้โอนเงินนอกข้อตกลง',
      ),
      isNull,
    );
    final count = appState.reports.length;
    expect(
      appState.submitReport(
        reportedUserId: 'user_03',
        orderId: 'ORD-2026-0808',
        productId: 'prod_2',
        reason: ReportReason.paymentScam,
        detail: 'รายงานซ้ำ',
      ),
      contains('ส่งรายงาน'),
    );
    expect(appState.reports, hasLength(count));

    appState.currentUser = appState.userById('admin_01')!;
    final adminReports = appState.adminReports();
    expect(adminReports.isSuccess, isTrue);
    expect(adminReports.value!.first.reportedUserId, 'user_03');
  });

  test('disputes enforce the seven-day window and admin audit transitions', () {
    final pending = createOrder(appState, 'prod_2', 'user_03');
    expect(
      appState.disputeOrder(pending.id, 'สินค้าเสียหาย', 'พบรอยแตก'),
      isNull,
    );
    final disputeReport = appState.reports.firstWhere(
      (report) => report.orderId == pending.id,
    );
    expect(appState.completeOrder(pending.id), contains('รอนัดรับ'));
    expect(appState.cancelOrder(pending.id, 'เปลี่ยนใจ'), contains('รอนัดรับ'));

    appState.currentUser = appState.userById('admin_01')!;
    final eventCount = orderById(appState, pending.id).events.length;
    expect(
      appState.resolveReport(
        disputeReport.id,
        action: AdminReportAction.dismiss,
        adminNote: 'ตรวจสอบแล้ว',
      ),
      isNull,
    );
    expect(orderById(appState, pending.id).status, OrderStatus.pending);
    expect(orderById(appState, pending.id).events, hasLength(eventCount + 1));
    expect(
      appState.reports.firstWhere((r) => r.id == disputeReport.id).adminId,
      'admin_01',
    );
    expect(
      appState.reports.firstWhere((r) => r.id == disputeReport.id).adminNote,
      'ตรวจสอบแล้ว',
    );
    expect(
      appState.notifications.any(
        (notification) =>
            notification.userId == 'user_01' &&
            notification.type == AppNotificationType.reportUpdated,
      ),
      isTrue,
    );

    appState.currentUser = appState.userById('user_01')!;
    final completed = createOrder(appState, 'prod_7', 'user_03');
    appState.currentUser = appState.userById('user_03')!;
    appState.markOrderHandedOver(completed.id);
    appState.currentUser = appState.userById('user_01')!;
    appState.completeOrder(completed.id);
    final fixedNow = DateTime(2026, 11, 22, 12);
    appState.setClockForTesting(() => fixedNow);
    final completedAtBoundary = orderById(
      appState,
      completed.id,
    ).copyWith(completedAt: fixedNow.subtract(const Duration(days: 7)));
    replaceOrder(appState, completedAtBoundary);
    expect(
      appState.disputeOrder(completed.id, 'พบปัญหา', 'รายละเอียด'),
      isNull,
    );
    final boundaryReport = appState.reports.firstWhere(
      (report) => report.orderId == completed.id,
    );
    appState.currentUser = appState.userById('admin_01')!;
    appState.resolveReport(
      boundaryReport.id,
      action: AdminReportAction.dismiss,
      adminNote: '',
    );
    replaceOrder(
      appState,
      orderById(appState, completed.id).copyWith(
        completedAt: fixedNow.subtract(const Duration(days: 7, hours: 1)),
      ),
    );
    appState.currentUser = appState.userById('user_01')!;
    expect(
      appState.disputeOrder(completed.id, 'พบปัญหา', 'รายละเอียด'),
      contains('7 วัน'),
    );
    appState.currentUser = appState.userById('user_02')!;
    expect(
      appState.disputeOrder(completed.id, 'พบปัญหา', 'รายละเอียด'),
      contains('ผู้ซื้อหรือผู้ขาย'),
    );
    final cancelled = createOrder(appState, 'prod_4', 'user_05');
    appState.cancelOrder(cancelled.id, 'เปลี่ยนใจ');
    expect(
      appState.disputeOrder(cancelled.id, 'พบปัญหา', 'รายละเอียด'),
      contains('รอนัดรับ'),
    );
  });

  test(
    'admin cancellation restores reserved listings and records order event',
    () {
      final order = createOrder(appState, 'prod_2', 'user_03');
      appState.disputeOrder(order.id, 'ปัญหา', 'รายละเอียด');
      final report = appState.reports.firstWhere(
        (item) => item.orderId == order.id,
      );
      appState.currentUser = appState.userById('admin_01')!;
      final eventCount = orderById(appState, order.id).events.length;
      expect(
        appState.resolveReport(
          report.id,
          action: AdminReportAction.cancelOrder,
          adminNote: 'ยกเลิกหลังตรวจสอบ',
        ),
        isNull,
      );
      expect(orderById(appState, order.id).status, OrderStatus.cancelled);
      expect(orderById(appState, order.id).events, hasLength(eventCount + 1));
      expect(productById(appState, 'prod_2').status, ListingStatus.active);
    },
  );

  test(
    'admin cancellation after completed-order dispute restores sold listing',
    () {
      final order = createOrder(appState, 'prod_7', 'user_03');
      appState.currentUser = appState.userById('user_03')!;
      appState.markOrderHandedOver(order.id);
      appState.currentUser = appState.userById('user_01')!;
      expect(appState.completeOrder(order.id), isNull);
      expect(productById(appState, 'prod_7').status, ListingStatus.sold);

      expect(appState.disputeOrder(order.id, 'พบปัญหา', 'รายละเอียด'), isNull);
      final report = appState.reports.firstWhere(
        (item) => item.orderId == order.id,
      );
      appState.currentUser = appState.userById('admin_01')!;
      expect(
        appState.resolveReport(
          report.id,
          action: AdminReportAction.cancelOrder,
          adminNote: 'ยกเลิกหลังตรวจสอบ',
        ),
        isNull,
      );
      expect(orderById(appState, order.id).status, OrderStatus.cancelled);
      expect(productById(appState, 'prod_7').status, ListingStatus.active);
    },
  );

  test('admin role guards and suspension protect users and pending orders', () {
    final pendingOrder = appState.orders.firstWhere(
      (order) => order.status == OrderStatus.pending,
    );
    final originalReportCount = appState.reports.length;
    final originalUser = appState.userById('user_02')!;
    final sellerProductIndex = appState.products.indexWhere(
      (product) => product.id == 'prod_1',
    );
    appState.products[sellerProductIndex] = appState
        .products[sellerProductIndex]
        .copyWith(status: ListingStatus.active);
    expect(appState.suspendUser('user_02', 'reason'), contains('ผู้ดูแล'));
    expect(appState.unsuspendUser('user_02'), contains('ผู้ดูแล'));
    expect(
      appState.resolveReport(
        'REP-002',
        action: AdminReportAction.dismiss,
        adminNote: '',
      ),
      contains('ผู้ดูแล'),
    );
    expect(appState.adminUsers().isSuccess, isFalse);
    expect(appState.reports, hasLength(originalReportCount));
    expect(appState.userById('user_02')!.isSuspended, originalUser.isSuspended);

    appState.currentUser = appState.userById('admin_01')!;
    expect(appState.suspendUser('admin_01', 'reason'), contains('ตัวเอง'));
    appState.users = [
      ...appState.users,
      UserModel(id: 'admin_02', name: 'ผู้ดูแลอีกคน', role: UserRole.admin),
    ];
    expect(appState.suspendUser('admin_02', 'reason'), contains('ผู้ดูแลระบบ'));
    appState.users.removeWhere((user) => user.id == 'admin_02');
    expect(appState.suspendUser('user_02', 'เหตุผลทดสอบ'), isNull);
    expect(orderById(appState, pendingOrder.id).status, OrderStatus.pending);
    appState.currentUser = appState.userById('user_02')!;
    expect(
      appState.sendTextMessage('chat_01', 'ข้อความทดสอบ'),
      contains('บัญชีนี้ถูกระงับ'),
    );
    expect(appState.currentUser.role, UserRole.guest);
    appState.loginAsGuest();
    expect(
      appState.loginWithPhoneAndPassword('0800000002', 'password123'),
      isFalse,
    );
    expect(appState.lastLoginError, contains('บัญชีนี้ถูกระงับ'));
    appState.currentUser = appState.userById('user_01')!;
    expect(
      appState.productsNearby(radiusKm: 100).map((item) => item.product.id),
      isNot(contains('prod_1')),
    );
    appState.currentUser = appState.userById('admin_01')!;
    expect(appState.unsuspendUser('user_02'), isNull);
    appState.currentUser = appState.userById('user_01')!;
    expect(
      appState.productsNearby(radiusKm: 100).map((item) => item.product.id),
      contains('prod_1'),
    );
  });

  test(
    'area alerts match enabled radius and categories and messages aggregate',
    () {
      appState.currentUser = appState.userById('user_02')!;
      appState.updateCurrentUserArea(
        latitude: kDefaultCenter.lat,
        longitude: kDefaultCenter.lng,
        label: 'พื้นที่ทดสอบ',
      );
      appState.updateAreaAlertSubscription(
        enabled: true,
        radiusKm: 5,
        categories: const ['หนังสือ'],
      );
      appState.currentUser = appState.userById('user_03')!;
      appState.updateCurrentUserArea(
        latitude: kDefaultCenter.lat,
        longitude: kDefaultCenter.lng,
        label: 'พื้นที่ทดสอบ',
      );
      appState.updateAreaAlertSubscription(
        enabled: true,
        radiusKm: 5,
        categories: const ['เสื้อผ้า & เครื่องแต่งกาย'],
      );
      appState.currentUser = appState.userById('user_04')!;
      appState.updateCurrentUserArea(
        latitude: kDefaultCenter.lat,
        longitude: kDefaultCenter.lng,
        label: 'พื้นที่ทดสอบ',
      );
      appState.updateAreaAlertSubscription(
        enabled: true,
        radiusKm: 5,
        categories: const ['หนังสือ'],
      );
      appState.currentUser = appState.userById('user_07')!;
      appState.updateCurrentUserArea(
        latitude: 0.1,
        longitude: 0.1,
        label: 'พื้นที่ไกล',
      );
      appState.updateAreaAlertSubscription(
        enabled: true,
        radiusKm: 1,
        categories: const ['หนังสือ'],
      );
      expect(
        appState.updateAreaAlertSubscription(
          enabled: true,
          radiusKm: 21,
          categories: const [],
        ),
        contains('1 ถึง 20'),
      );
      appState.currentUser = appState.userById('user_01')!;
      appState.blockUser('user_04');

      final listing = appState.addListing(
        title: 'หนังสือแจ้งเตือนทดสอบ',
        description: 'รายละเอียด',
        price: 10,
        tradeFor: '',
        type: ListingType.sell,
        category: 'หนังสือ',
        condition: 'สภาพดี',
        exactLocation: kDefaultCenter,
        locationLabel: 'ย่านทดสอบ',
        exactAddress: 'ถนนตัวอย่าง 1',
        pickupType: PickupType.discussInChat,
        imageUrl: '',
        productImages: const [],
      );
      expect(
        appState.notifications.where(
          (item) => item.refId == listing.id && item.userId == 'user_02',
        ),
        hasLength(1),
      );
      expect(
        appState.notifications.where(
          (item) => item.refId == listing.id && item.userId == 'user_03',
        ),
        isEmpty,
      );
      expect(
        appState.notifications.where(
          (item) => item.refId == listing.id && item.userId == 'user_04',
        ),
        isEmpty,
      );
      expect(
        appState.notifications.where(
          (item) => item.refId == listing.id && item.userId == 'user_07',
        ),
        isEmpty,
      );

      final conversation = appState.conversations.firstWhere(
        (item) => item.id == 'chat_02',
      );
      appState.sendTextMessage(conversation.id, 'ข้อความหนึ่ง');
      appState.sendTextMessage(conversation.id, 'ข้อความสอง');
      final messageNotifications = appState.notifications
          .where(
            (item) =>
                item.userId == 'user_03' &&
                item.type == AppNotificationType.newMessage &&
                item.refId == conversation.id,
          )
          .toList();
      expect(messageNotifications, hasLength(1));
      expect(messageNotifications.single.isRead, isFalse);
      appState.currentUser = appState.userById('user_03')!;
      appState.markConversationRead(conversation.id);
      expect(appState.unreadNotificationCount, 0);
      expect(
        appState.notifications
            .firstWhere((item) => item.id == messageNotifications.single.id)
            .isRead,
        isTrue,
      );
    },
  );

  test('shared meetup plan contains no exact address or coordinates', () {
    final text = meetupPlanText(
      productTitle: 'สินค้า',
      partnerName: 'ผู้ขาย',
      placeLabel: 'บ้านผู้ขาย (ย่านเมือง)',
      scheduledAt: DateTime(2026, 11, 23, 12),
    );
    expect(text, contains('บ้านผู้ขาย (ย่านเมือง)'));
    expect(text, isNot(contains('บ้านเลขที่ 99')));
    expect(text, isNot(contains('12.6112')));
    expect(text, isNot(contains('102.1031')));
  });
}

ProductModel productById(AppState appState, String id) =>
    appState.products.firstWhere((product) => product.id == id);

OrderModel orderById(AppState appState, String id) =>
    appState.orders.firstWhere((order) => order.id == id);

void replaceOrder(AppState appState, OrderModel order) {
  final index = appState.orders.indexWhere((item) => item.id == order.id);
  appState.orders[index] = order;
}

OrderModel createOrder(AppState appState, String productId, String sellerId) {
  appState.currentUser = appState.userById('user_01')!;
  expect(appState.addToCart(productById(appState, productId)), isNull);
  final result = appState.createOrderForSeller(
    sellerId,
    paymentMethod: PaymentMethod.cashOnHandover,
  );
  expect(result.isSuccess, isTrue);
  return result.order!;
}
