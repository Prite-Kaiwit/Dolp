import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/models/order.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/review.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/models/chat.dart';
import 'package:moor_market/models/meetup_agreement.dart';
import 'package:moor_market/models/notification.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();
  late List<ProductModel> originalProducts;
  late List<ProductModel> originalCart;
  late List<OrderModel> originalOrders;
  late List<ReviewModel> originalReviews;
  late List<UserModel> originalUsers;
  late List<AppNotification> originalNotifications;
  late List<ChatConversation> originalConversations;
  late List<MeetupAgreement> originalMeetups;

  setUp(() {
    originalProducts = List<ProductModel>.of(appState.products);
    originalCart = List<ProductModel>.of(appState.cartItems);
    originalOrders = List<OrderModel>.of(appState.orders);
    originalReviews = List<ReviewModel>.of(appState.reviews);
    originalUsers = List<UserModel>.of(appState.users);
    originalNotifications = List<AppNotification>.of(appState.notifications);
    originalConversations = List<ChatConversation>.of(appState.conversations);
    originalMeetups = List<MeetupAgreement>.of(appState.meetupAgreements);
    appState.cartItems.clear();
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
  });

  tearDown(() {
    appState.products = originalProducts;
    appState.cartItems = originalCart;
    appState.orders = originalOrders;
    appState.reviews = originalReviews;
    appState.users = originalUsers;
    appState.notifications = originalNotifications;
    appState.conversations = originalConversations;
    appState.meetupAgreements = originalMeetups;
    appState.loginWithPhoneAndPassword('0800000001', 'password123');
  });

  test(
    'orders are grouped per seller and retain other sellers in the cart',
    () {
      final firstSellerProducts = [
        _product(appState, 'prod_2'),
        _product(appState, 'prod_7'),
      ];
      final otherSellerProduct = _product(appState, 'prod_4');
      for (final product in [...firstSellerProducts, otherSellerProduct]) {
        expect(appState.addToCart(product), isNull);
      }
      expect(appState.cartItems, hasLength(3));

      final firstOrder = appState.createOrderForSeller(
        'user_03',
        paymentMethod: PaymentMethod.cashOnHandover,
      );
      expect(firstOrder.isSuccess, isTrue);
      expect(firstOrder.order!.items.map((item) => item.productId).toSet(), {
        'prod_2',
        'prod_7',
      });
      expect(firstOrder.order!.totalPrice, 900);
      expect(appState.cartItems.map((item) => item.id), ['prod_4']);

      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      expect(
        appState.addToCart(firstSellerProducts.first),
        contains('ไม่พร้อมขาย'),
      );

      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      final secondOrder = appState.createOrderForSeller(
        'user_05',
        paymentMethod: PaymentMethod.transferOnHandover,
      );
      expect(secondOrder.isSuccess, isTrue);
      expect(appState.cartItems, isEmpty);
      expect(secondOrder.order!.items, hasLength(1));
    },
  );

  test(
    'reserved products disappear, cancel restores, completion marks sold',
    () {
      final product = _product(appState, 'prod_7');
      expect(appState.addToCart(product), isNull);
      final result = appState.createOrderForSeller(
        product.sellerId,
        paymentMethod: PaymentMethod.cashOnHandover,
      );
      final order = result.order!;
      expect(_product(appState, product.id).status, ListingStatus.reserved);
      expect(
        appState.productsNearby(radiusKm: 20).map((item) => item.product.id),
        isNot(contains(product.id)),
      );

      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      expect(appState.addToCart(product), contains('ไม่พร้อมขาย'));
      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      expect(appState.cancelOrder(order.id, 'เปลี่ยนใจ'), isNull);
      expect(_product(appState, product.id).status, ListingStatus.active);

      expect(appState.addToCart(product), isNull);
      final hideThenCancel = appState
          .createOrderForSeller(
            product.sellerId,
            paymentMethod: PaymentMethod.cashOnHandover,
          )
          .order!;
      appState.currentUser = appState.userById(product.sellerId)!;
      expect(
        appState.setListingStatus(product.id, ListingStatus.hidden),
        isNull,
      );
      expect(_product(appState, product.id).status, ListingStatus.reserved);
      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      expect(appState.cancelOrder(hideThenCancel.id, 'เปลี่ยนใจ'), isNull);
      expect(_product(appState, product.id).status, ListingStatus.hidden);
      appState.currentUser = appState.userById(product.sellerId)!;
      expect(
        appState.setListingStatus(product.id, ListingStatus.active),
        isNull,
      );
      appState.loginWithPhoneAndPassword('0800000001', 'password123');

      expect(appState.addToCart(product), isNull);
      final completedResult = appState.createOrderForSeller(
        product.sellerId,
        paymentMethod: PaymentMethod.cashOnHandover,
      );
      final completedOrder = completedResult.order!;
      appState.currentUser = appState.userById(product.sellerId)!;
      expect(appState.markOrderHandedOver(completedOrder.id), isNull);
      expect(appState.orders.first.status, OrderStatus.pending);
      expect(appState.orders.first.events, hasLength(1));

      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      expect(appState.completeOrder(completedOrder.id), isNull);
      expect(_product(appState, product.id).status, ListingStatus.sold);
      expect(appState.orders.first.events.last.status, OrderStatus.completed);
      expect(appState.cancelOrder(completedOrder.id, 'เปลี่ยนใจ'), isNotNull);
      expect(
        appState.orders
            .firstWhere((item) => item.id == completedOrder.id)
            .status,
        OrderStatus.completed,
      );
    },
  );

  test('unavailable item rejects the entire seller group atomically', () {
    final available = _product(appState, 'prod_2');
    final stale = _product(appState, 'prod_7');
    appState.addToCart(available);
    appState.addToCart(stale);
    final index = appState.products.indexWhere((item) => item.id == stale.id);
    appState.products[index] = stale.copyWith(status: ListingStatus.reserved);
    final orderCount = appState.orders.length;

    final result = appState.createOrderForSeller(
      'user_03',
      paymentMethod: PaymentMethod.cashOnHandover,
    );
    expect(result.isSuccess, isFalse);
    expect(result.error, contains('ไม่พร้อมขาย'));
    expect(appState.orders, hasLength(orderCount));
    expect(_product(appState, available.id).status, ListingStatus.active);
    expect(appState.cartItems, hasLength(2));
  });

  test(
    'latest accepted meetup and shared address are copied onto the order',
    () {
      final conversation = appState.openConversationForProduct('prod_2')!;
      expect(
        appState.proposeMeetup(
          conversationId: conversation.id,
          pickupType: PickupType.sellerHome,
          placeLabel: '',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
        ),
        isNull,
      );
      final agreement = appState.meetupAgreements.last;
      appState.currentUser = appState.userById('user_03')!;
      expect(appState.respondMeetup(agreement.id, accept: true), isNull);
      expect(appState.shareExactAddress(conversation.id), isNull);
      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      expect(appState.addToCart(_product(appState, 'prod_2')), isNull);
      final order = appState
          .createOrderForSeller(
            'user_03',
            paymentMethod: PaymentMethod.transferOnHandover,
          )
          .order!;

      expect(order.meetupId, agreement.id);
      expect(order.pickupType, PickupType.sellerHome);
      expect(order.agreedPlaceLabel, agreement.placeLabel);
      expect(order.agreedTime, agreement.scheduledAt);
      expect(appState.sharedAddressForOrder(order.id), isNotEmpty);
      expect(appState.conversationForOrder(order.id)?.id, conversation.id);
      expect(appState.cancelOrder(order.id, 'cleanup'), isNull);
    },
  );

  test(
    'guest and owner cannot add items; duplicates and totals stay consistent',
    () {
      final product = _product(appState, 'prod_2');
      expect(appState.addToCart(product), isNull);
      expect(appState.addToCart(product), isNull);
      expect(appState.cartItems, hasLength(1));
      expect(
        appState.cartItems.fold(0.0, (sum, item) => sum + item.price),
        650,
      );
      appState.removeFromCart(product.id);
      expect(appState.cartItems, isEmpty);

      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      expect(
        appState.addToCart(_product(appState, 'prod_1')),
        contains('ตัวเอง'),
      );
      appState.loginAsGuest();
      expect(appState.addToCart(product), contains('เข้าสู่ระบบ'));
      expect(appState.cartItems, isEmpty);
      appState.clearCart();
      expect(appState.cartItems, isEmpty);
    },
  );

  test(
    'transitions are guarded, logged, and disputes can be resolved or cancelled',
    () {
      final product = _product(appState, 'prod_2');
      appState.addToCart(product);
      final pending = appState
          .createOrderForSeller(
            product.sellerId,
            paymentMethod: PaymentMethod.cashOnHandover,
          )
          .order!;
      expect(appState.completeOrder(pending.id), isNull);
      expect(appState.orders.first.events, hasLength(2));
      expect(appState.completeOrder(pending.id), isNotNull);
      expect(appState.cancelOrder(pending.id, 'เปลี่ยนใจ'), isNotNull);

      final other = _product(appState, 'prod_6');
      appState.addToCart(other);
      final disputed = appState
          .createOrderForSeller(
            other.sellerId,
            paymentMethod: PaymentMethod.transferOnHandover,
          )
          .order!;
      expect(
        appState.disputeOrder(disputed.id, 'สินค้าเสียหาย', 'รายละเอียด'),
        isNull,
      );
      final report = appState.reports.firstWhere(
        (item) => item.orderId == disputed.id,
      );
      final eventsBeforeResolve = appState.orders
          .firstWhere((item) => item.id == disputed.id)
          .events
          .length;

      appState.currentUser = appState.userById('admin_01')!;
      expect(
        appState.resolveDispute(report.id, ReportResolution.close),
        isNull,
      );
      final restored = appState.orders.firstWhere(
        (item) => item.id == disputed.id,
      );
      expect(restored.status, OrderStatus.pending);
      expect(restored.previousStatus, isNull);
      expect(restored.events, hasLength(eventsBeforeResolve + 1));

      appState.loginWithPhoneAndPassword('0800000001', 'password123');
      expect(
        appState.disputeOrder(disputed.id, 'ปัญหาอีกครั้ง', 'รายละเอียด'),
        isNull,
      );
      final secondReport = appState.reports.firstWhere(
        (item) => item.orderId == disputed.id,
        orElse: () => appState.reports.first,
      );
      appState.currentUser = appState.userById('admin_01')!;
      expect(
        appState.resolveDispute(secondReport.id, ReportResolution.cancelOrder),
        isNull,
      );
      expect(
        appState.orders.firstWhere((item) => item.id == disputed.id).status,
        OrderStatus.cancelled,
      );
      expect(_product(appState, other.id).status, ListingStatus.active);
    },
  );

  test(
    'reviews validate participants, completion, bounds, and update averages',
    () {
      appState.users = [
        ...appState.users,
        UserModel(id: 'seller_review_test', name: 'ผู้ขายทดสอบ'),
        UserModel(id: 'seller_review_edges', name: 'ผู้ขายขอบเขต'),
      ];
      final pending = _createOrder(
        appState,
        'review-pending',
        'seller_review_test',
      );
      expect(
        appState.submitReview(
          orderId: pending.id,
          rating: 5,
          tags: const [],
          comment: '',
        ),
        contains('หลังคำสั่งซื้อสำเร็จ'),
      );
      expect(appState.cancelOrder(pending.id, 'cleanup'), isNull);

      final first = _completeOrder(
        appState,
        'review-average-1',
        'seller_review_test',
      );
      final second = _completeOrder(
        appState,
        'review-average-2',
        'seller_review_test',
      );
      expect(
        appState.submitReview(
          orderId: first.id,
          rating: 0,
          tags: const [],
          comment: '',
        ),
        isNotNull,
      );
      expect(
        appState.submitReview(
          orderId: first.id,
          rating: 6,
          tags: const [],
          comment: '',
        ),
        isNotNull,
      );
      expect(
        appState.submitReview(
          orderId: first.id,
          rating: 5,
          tags: const [],
          comment: 'x' * 501,
        ),
        contains('500'),
      );
      expect(
        appState.submitReview(
          orderId: first.id,
          rating: 5,
          tags: const ['ตรงเวลา'],
          comment: 'x' * 500,
        ),
        isNull,
      );
      expect(
        appState.submitReview(
          orderId: first.id,
          rating: 5,
          tags: const [],
          comment: '',
        ),
        contains('ไปแล้ว'),
      );
      expect(
        appState.submitReview(
          orderId: second.id,
          rating: 3,
          tags: const [],
          comment: '',
        ),
        isNull,
      );
      expect(appState.userById('seller_review_test')!.rating, 4);
      expect(appState.userById('seller_review_test')!.reviewCount, 2);

      final low = _completeOrder(
        appState,
        'review-edge-1',
        'seller_review_edges',
      );
      final high = _completeOrder(
        appState,
        'review-edge-2',
        'seller_review_edges',
      );
      expect(
        appState.submitReview(
          orderId: low.id,
          rating: 1,
          tags: const [],
          comment: '',
        ),
        isNull,
      );
      expect(
        appState.submitReview(
          orderId: high.id,
          rating: 5,
          tags: const [],
          comment: '',
        ),
        isNull,
      );
      expect(appState.userById('seller_review_edges')!.rating, 3);
      expect(appState.userById('seller_review_edges')!.reviewCount, 2);

      final outsider = _completeOrder(
        appState,
        'review-outsider',
        'seller_review_test',
      );
      appState.loginWithPhoneAndPassword('0800000002', 'password123');
      expect(
        appState.submitReview(
          orderId: outsider.id,
          rating: 4,
          tags: const [],
          comment: '',
        ),
        contains('ไม่ใช่ผู้ซื้อหรือผู้ขาย'),
      );
    },
  );
}

ProductModel _product(AppState state, String id) =>
    state.products.firstWhere((product) => product.id == id);

OrderModel _createOrder(AppState state, String productId, String sellerId) {
  final product = ProductModel(
    id: productId,
    title: productId,
    description: '',
    price: 100,
    type: ListingType.sell,
    category: 'ทดสอบ',
    condition: 'สภาพดี',
    publicLocation: kDefaultCenter,
    imageUrl: '',
    sellerId: sellerId,
    sellerName: sellerId,
    sellerAreaLabel: 'ย่านทดสอบ',
  );
  state.addProduct(product);
  expect(state.addToCart(product), isNull);
  final result = state.createOrderForSeller(
    sellerId,
    paymentMethod: PaymentMethod.cashOnHandover,
  );
  expect(result.isSuccess, isTrue);
  return result.order!;
}

OrderModel _completeOrder(AppState state, String productId, String sellerId) {
  final order = _createOrder(state, productId, sellerId);
  state.currentUser = state.userById(sellerId)!;
  expect(state.markOrderHandedOver(order.id), isNull);
  state.loginWithPhoneAndPassword('0800000001', 'password123');
  expect(state.completeOrder(order.id), isNull);
  return order;
}
