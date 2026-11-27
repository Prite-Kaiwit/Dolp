import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/meetup_agreement.dart';
import 'package:moor_market/models/order.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/product_image_data.dart';
import 'package:moor_market/models/report.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/persistence/in_memory_persistence_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restart restores listings, private locations, orders, reviews, chat, safety, and cart',
    () async {
      final store = InMemoryPersistenceStore();
      final state = await _newState(store);
      expect(state.currentUser.role.name, 'guest');
      expect(state.users, isNotEmpty);

      expect(
        state.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn,
        isTrue,
      );
      final product = state.addListing(
        title: 'Persistence test listing',
        description: 'Testing saved content',
        price: 325,
        tradeFor: '',
        type: ListingType.sell,
        category: 'อื่น ๆ',
        condition: 'สภาพดี',
        exactLocation: GeoLocation(12.6112, 102.1031),
        locationLabel: 'ย่านตัวอย่าง',
        exactAddress: 'บ้านเลขที่ 123',
        pickupType: PickupType.discussInChat,
        imageUrl: '',
        productImages: [
          ProductImageData.memory(Uint8List.fromList([7, 8, 9])),
        ],
      );
      expect(jsonEncode(product.toJson()), isNot(contains('บ้านเลขที่ 123')));
      expect(
        state.getExactLocationFor(product.id, 'user_02')?.exactAddress,
        'บ้านเลขที่ 123',
      );
      expect(
        state.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn,
        isTrue,
      );
      final conversation = state.openConversationForProduct(product.id)!;
      expect(state.getExactLocationFor(product.id, 'user_01'), isNull);
      expect(state.sendTextMessage(conversation.id, 'สอบถามสินค้า'), isNull);
      expect(
        state.sendImageMessage(
          conversation.id,
          Uint8List.fromList([1, 2, 3, 4]),
        ),
        isNull,
      );
      expect(
        state.proposeMeetup(
          conversationId: conversation.id,
          pickupType: PickupType.suggestedSpot,
          placeLabel: 'จุดสาธารณะ',
          scheduledAt: DateTime.now().add(const Duration(days: 1)),
        ),
        isNull,
      );
      final meetup = state.meetupAgreements.last;
      expect(
        state.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(state.respondMeetup(meetup.id, accept: true), isNull);
      expect(state.shareExactAddress(conversation.id), isNull);
      expect(
        state.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(
        state.getExactLocationFor(product.id, 'user_01')?.exactAddress,
        'บ้านเลขที่ 123',
      );

      expect(state.addToCart(product), isNull);
      final completed = state
          .createOrderForSeller(
            'user_02',
            paymentMethod: PaymentMethod.cashOnHandover,
          )
          .order!;
      expect(completed.meetupId, meetup.id);
      expect(state.completeOrder(completed.id), isNull);
      expect(
        state.submitReview(
          orderId: completed.id,
          rating: 5,
          tags: const ['สื่อสารดี'],
          comment: 'ดีมาก',
        ),
        isNull,
      );
      expect(
        state.submitReport(
          reportedUserId: 'user_02',
          reason: ReportReason.other,
          detail: 'ขอเก็บเป็นตัวอย่าง',
          orderId: completed.id,
        ),
        isNull,
      );

      expect(
        state.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn,
        isTrue,
      );
      final blockedProduct = state.addListing(
        title: 'Blocked pending listing',
        description: '',
        price: 100,
        tradeFor: '',
        type: ListingType.sell,
        category: 'อื่น ๆ',
        condition: 'สภาพดี',
        exactLocation: GeoLocation(12.6112, 102.1031),
        locationLabel: 'ย่านตัวอย่าง',
        exactAddress: 'อีกหนึ่งที่อยู่จริง',
        pickupType: PickupType.discussInChat,
        imageUrl: '',
        productImages: const [],
      );
      expect(
        state.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(state.addToCart(blockedProduct), isNull);
      final blockedPending = state
          .createOrderForSeller(
            'user_02',
            paymentMethod: PaymentMethod.transferOnHandover,
          )
          .order!;
      expect(blockedPending.status, OrderStatus.pending);
      expect(
        state.addToCart(
          state.products.firstWhere((item) => item.id == 'prod_2'),
        ),
        isNull,
      );
      final suspendedPending = state
          .createOrderForSeller(
            'user_03',
            paymentMethod: PaymentMethod.transferOnHandover,
          )
          .order!;
      expect(state.blockUser('user_02'), isNull);
      expect(
        state.signInVerifiedPhone('0800000009') == PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(state.suspendUser('user_03', 'Review test'), isNull);
      expect(
        state.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(
        state.updateAreaAlertSubscription(
          enabled: true,
          radiusKm: 3,
          categories: const ['อื่น ๆ'],
        ),
        isNull,
      );
      state.acknowledgeSafetyTips();
      expect(
        state.addToCart(
          state.products.firstWhere((item) => item.id == 'prod_4'),
        ),
        isNull,
      );
      final unreadBefore = state.unreadNotificationCount;
      final ratingBefore = state.userById('user_02')!.rating;
      final tabCountBefore = state.pendingOrderCount;

      await state.flush();
      final saved = jsonDecode(store.payload!) as Map<String, dynamic>;
      expect(saved.containsKey('credentials'), isFalse);
      final savedProduct =
          (saved['products'] as List).firstWhere(
                (item) => (item as Map)['id'] == product.id,
              )
              as Map;
      expect(jsonEncode(savedProduct), isNot(contains('exactAddress')));
      expect(jsonEncode(savedProduct), isNot(contains('exactLat')));

      state.dispose();
      final restored = await _newState(store);
      expect(restored.currentUser.id, 'user_01');
      expect(restored.products.any((item) => item.id == product.id), isTrue);
      expect(
        restored.products
            .firstWhere((item) => item.id == product.id)
            .productImages
            .single
            .bytes,
        [7, 8, 9],
      );
      expect(
        restored.getExactLocationFor(product.id, 'user_01')?.exactAddress,
        'บ้านเลขที่ 123',
      );
      expect(restored.getExactLocationFor(product.id, 'user_03'), isNull);
      expect(
        restored.orders.firstWhere((item) => item.id == completed.id).status,
        OrderStatus.completed,
      );
      expect(
        restored.orders
            .firstWhere((item) => item.id == completed.id)
            .events
            .last
            .status,
        OrderStatus.completed,
      );
      expect(
        restored.orders
            .firstWhere((item) => item.id == blockedPending.id)
            .status,
        OrderStatus.pending,
      );
      expect(
        restored.orders
            .firstWhere((item) => item.id == suspendedPending.id)
            .status,
        OrderStatus.pending,
      );
      expect(
        restored.getExactLocationFor(blockedProduct.id, 'user_01'),
        isNull,
      );
      expect(
        restored.signInVerifiedPhone('0800000002') ==
            PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(
        restored
            .getExactLocationFor(blockedProduct.id, 'user_02')
            ?.exactAddress,
        'อีกหนึ่งที่อยู่จริง',
      );
      expect(
        restored.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(
        restored.reviews.any((item) => item.orderId == completed.id),
        isTrue,
      );
      expect(
        restored.reports.any((item) => item.orderId == completed.id),
        isTrue,
      );
      expect(restored.areUsersBlocked('user_01', 'user_02'), isTrue);
      expect(restored.userById('user_03')!.isSuspended, isTrue);
      expect(restored.areaAlertSubscriptionFor('user_01').radiusKm, 3);
      expect(restored.shouldShowSafetyTips, isFalse);
      expect(restored.cartItems.map((item) => item.id), contains('prod_4'));
      expect(restored.unreadNotificationCount, unreadBefore);
      expect(restored.userById('user_02')!.rating, ratingBefore);
      expect(restored.pendingOrderCount, tabCountBefore);
      final restoredConversation = restored.conversations.firstWhere(
        (item) => item.id == conversation.id,
      );
      expect(
        restoredConversation.messages.any(
          (message) => message.text == 'สอบถามสินค้า',
        ),
        isTrue,
      );
      expect(
        restoredConversation.messages.any(
          (message) => message.imageBytes?.length == 4,
        ),
        isTrue,
      );
      expect(
        restored.meetupAgreements.any(
          (item) =>
              item.id == meetup.id && item.status == MeetupStatus.accepted,
        ),
        isTrue,
      );
      restored.dispose();
    },
  );

  test(
    'seed only fills an empty store; accounts and session survive restart',
    () async {
      final store = InMemoryPersistenceStore();
      final initial = await _newState(store);
      final originalCount = initial.products.length;
      expect(initial.currentUser.role.name, 'guest');
      expect(
        initial.signInVerifiedPhone('0899999999'),
        PhoneSignInResult.needsRegistration,
      );
      expect(
        initial.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn,
        isTrue,
      );
      initial.products.first = initial.products.first.copyWith(
        title: 'User edit',
      );
      await initial.flush();
      initial.dispose();

      final restored = await _newState(store);
      expect(restored.products, hasLength(originalCount));
      expect(restored.products.first.title, 'User edit');
      expect(
        restored.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn,
        isTrue,
      );
      restored.loginAsGuest();
      await restored.flush();
      restored.dispose();

      final loggedOut = await _newState(store);
      expect(loggedOut.currentUser.role.name, 'guest');
      expect(
        loggedOut.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn,
        isTrue,
      );
      expect(
        loggedOut.registerVerifiedPhone(
          name: 'New user',
          phone: '0800000999',
          authUid: 'firebase-uid-999',
        ),
        isTrue,
      );
      await loggedOut.flush();
      loggedOut.dispose();

      final registered = await _newState(store);
      expect(registered.currentUser.phone, '0800000999');
      expect(registered.currentUser.authUid, 'firebase-uid-999');
      expect(
        registered.signInVerifiedPhone('0800000999'),
        PhoneSignInResult.signedIn,
      );
      registered.dispose();
    },
  );

  test(
    'missing schema migrates, unknown enum values fall back, and corruption is backed up',
    () async {
      final store = InMemoryPersistenceStore();
      final seeded = await _newState(store);
      final data = jsonDecode(store.payload!) as Map<String, dynamic>;
      data.remove('schemaVersion');
      final products = data['products'] as List;
      (products.first as Map<String, dynamic>)['type'] = 'futureListingType';
      (products.first as Map<String, dynamic>)['title'] = null;
      data['credentials'] = {
        '0800000001': {'userId': 'user_01', 'password': 'legacy-password'},
      };
      store.payload = jsonEncode(data);
      seeded.dispose();

      final migrated = await _newState(store);
      expect(migrated.products.first.type, ListingType.sell);
      expect(migrated.products.first.title, 'ประกาศสินค้า');
      expect(
        (jsonDecode(store.payload!) as Map<String, dynamic>)['schemaVersion'],
        AppState.schemaVersion,
      );
      // Old password credentials are dropped on the next save.
      expect(store.payload, isNot(contains('legacy-password')));
      expect(
        migrated.signInVerifiedPhone('0800000001'),
        PhoneSignInResult.signedIn,
      );
      migrated.dispose();

      store.payload = '{broken';
      final recovered = await _newState(store);
      expect(recovered.users, isNotEmpty);
      expect(store.corruptedBackups, ['{broken']);
      expect(recovered.takePersistenceWarning(), contains('เสียหาย'));
      expect(recovered.takePersistenceWarning(), isNull);
      recovered.dispose();
    },
  );

  test(
    'debounced changes flush, write errors are retained, and dispute age survives restart',
    () async {
      final store = InMemoryPersistenceStore();
      final state = await _newState(store);
      state.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
      state.updateCurrentUserArea(
        latitude: 12.5,
        longitude: 102.5,
        label: 'First',
      );
      state.updateCurrentUserArea(
        latitude: 12.6,
        longitude: 102.6,
        label: 'Latest',
      );
      await state.flush();
      state.dispose();

      final restored = await _newState(store);
      expect(restored.currentUser.homeLabel, 'Latest');
      final completedOrder = restored.orders.firstWhere(
        (order) => order.status == OrderStatus.completed,
      );
      final now = DateTime.utc(2026, 11, 23);
      restored.setClockForTesting(() => now);
      final index = restored.orders.indexWhere(
        (order) => order.id == completedOrder.id,
      );
      restored.orders[index] = completedOrder.copyWith(
        completedAt: now.subtract(const Duration(days: 7)),
      );
      restored.orders.add(
        completedOrder.copyWith(
          id: 'outside-dispute-window',
          completedAt: now.subtract(const Duration(days: 7, milliseconds: 1)),
        ),
      );
      await restored.flush();
      restored.dispose();

      final atWindow = await _newState(store);
      atWindow.setClockForTesting(() => now);
      final exactOrder = atWindow.orders.firstWhere(
        (order) => order.id == completedOrder.id,
      );
      expect(
        atWindow.disputeOrder(exactOrder.id, 'issue', 'within window'),
        isNull,
      );
      expect(
        atWindow.disputeOrder(
          'outside-dispute-window',
          'issue',
          'outside window',
        ),
        contains('ภายใน 7 วัน'),
      );
      atWindow.dispose();

      final failingStore = InMemoryPersistenceStore()
        ..failure = StateError('disk full');
      final unavailableStore = AppState.createForTesting(store: failingStore);
      await unavailableStore.initialize();
      unavailableStore.signInVerifiedPhone('0800000001') ==
          PhoneSignInResult.signedIn;
      await unavailableStore.flush();
      expect(unavailableStore.lastPersistenceError, contains('disk full'));
      unavailableStore.dispose();
    },
  );

  test(
    'suspended saved session returns to guest with a one-time warning',
    () async {
      final store = InMemoryPersistenceStore();
      final state = await _newState(store);
      state.signInVerifiedPhone('0800000009') == PhoneSignInResult.signedIn;
      expect(state.suspendUser('user_01', 'Policy review'), isNull);
      state.currentUser = state.userById('user_01')!;
      state.notifyListeners();
      await state.flush();
      state.dispose();

      final restored = await _newState(store);
      expect(restored.currentUser.role.name, 'guest');
      expect(restored.takePersistenceWarning(), contains('ถูกระงับ'));
      expect(restored.takePersistenceWarning(), isNull);
      expect(
        restored.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn,
        isFalse,
      );
      restored.dispose();
    },
  );

  test(
    'missing product references are ignored and debug reset reseeds',
    () async {
      final store = InMemoryPersistenceStore();
      final state = await _newState(store);
      final data = jsonDecode(store.payload!) as Map<String, dynamic>;
      data['cartItems'] = ['deleted-product'];
      data['products'] = [];
      store.payload = jsonEncode(data);
      state.dispose();

      final restored = await _newState(store);
      expect(restored.products, isEmpty);
      expect(restored.cartItems, isEmpty);
      expect(await restored.resetSampleData(), isTrue);
      expect(restored.products, isNotEmpty);
      expect(restored.cartItems, isEmpty);
      restored.dispose();
    },
  );
}

Future<AppState> _newState(InMemoryPersistenceStore store) async {
  final state = AppState.createForTesting(store: store);
  await state.initialize();
  return state;
}
