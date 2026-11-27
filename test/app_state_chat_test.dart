import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/chat_limits.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/meetup_agreement.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/state/app_state.dart';

void main() {
  final appState = AppState();
  late String conversationId;

  setUp(() {
    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    appState.conversations.clear();
    appState.meetupAgreements.clear();
    conversationId = appState.openConversationForProduct('prod_1')!.id;
  });

  String? propose({
    required PickupType pickupType,
    required DateTime scheduledAt,
    String placeLabel = 'จุดแนะนำในย่านเมือง',
    GeoLocation? spotLocation,
  }) => appState.proposeMeetup(
    conversationId: conversationId,
    pickupType: pickupType,
    placeLabel: placeLabel,
    scheduledAt: scheduledAt,
    spotLocation: spotLocation,
  );

  test('text messages reject blank and over-limit text without truncating', () {
    expect(appState.sendTextMessage(conversationId, ' \t\n '), isNotNull);
    expect(
      appState.sendTextMessage(conversationId, 'x' * kMaxChatMessageLength),
      isNull,
    );
    expect(
      appState.sendTextMessage(
        conversationId,
        'x' * (kMaxChatMessageLength + 1),
      ),
      isNotNull,
    );
    expect(
      appState.conversations.single.messages.last.text.length,
      kMaxChatMessageLength,
    );
  });

  test('a buyer reuses one conversation and cannot chat with own listing', () {
    final existing = appState.conversations.single;
    expect(appState.openConversationForProduct('prod_1')?.id, existing.id);
    expect(appState.conversations, hasLength(1));

    appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
    expect(appState.openConversationForProduct('prod_1'), isNull);
  });

  test('images enforce byte limit and guests cannot use chat actions', () {
    expect(
      appState.sendImageMessage(
        conversationId,
        Uint8List(kMaxChatImageBytes + 1),
      ),
      isNotNull,
    );
    expect(
      appState.sendImageMessage(conversationId, Uint8List.fromList([1, 2])),
      isNull,
    );

    appState.currentUser = UserModel(
      id: 'guest_01',
      name: 'ผู้เยี่ยมชม',
      role: UserRole.guest,
    );
    expect(appState.sendTextMessage(conversationId, 'สวัสดี'), isNotNull);
    expect(
      appState.sendImageMessage(conversationId, Uint8List.fromList([1])),
      isNotNull,
    );
    expect(
      appState.proposeMeetup(
        conversationId: conversationId,
        pickupType: PickupType.sellerHome,
        placeLabel: '',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      ),
      isNotNull,
    );
    expect(appState.respondMeetup('missing', accept: true), isNotNull);
    expect(appState.shareExactAddress(conversationId), isNotNull);
  });

  test('meetup proposals validate fields and supersede pending proposals', () {
    final past = DateTime.now().subtract(const Duration(minutes: 1));
    final tooFar = DateTime.now().add(
      const Duration(days: kMeetupMaxDaysAhead + 1),
    );
    expect(
      propose(pickupType: PickupType.sellerHome, scheduledAt: past),
      isNotNull,
    );
    expect(
      propose(pickupType: PickupType.sellerHome, scheduledAt: tooFar),
      isNotNull,
    );
    expect(
      propose(
        pickupType: PickupType.suggestedSpot,
        placeLabel: '',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      ),
      isNotNull,
    );
    expect(
      propose(
        pickupType: PickupType.agreedSpot,
        placeLabel: 'ลานสาธารณะ',
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      ),
      isNotNull,
    );

    expect(
      propose(
        pickupType: PickupType.sellerHome,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
      ),
      isNull,
    );
    final old = appState.meetupAgreements.single;
    expect(old.placeLabel, contains('บ้านผู้ขาย'));
    expect(old.spotLocation, isNull);
    expect(
      propose(
        pickupType: PickupType.agreedSpot,
        placeLabel: 'ลานสาธารณะ',
        spotLocation: GeoLocation(12.61, 102.10),
        scheduledAt: DateTime.now().add(const Duration(days: 2)),
      ),
      isNull,
    );
    expect(
      appState.meetupAgreements
          .firstWhere((agreement) => agreement.id == old.id)
          .status,
      MeetupStatus.superseded,
    );
    expect(appState.meetupAgreements.last.spotLocation, isNotNull);
  });

  test('only responder can respond and stale proposals cannot be accepted', () {
    propose(
      pickupType: PickupType.sellerHome,
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
    );
    final proposal = appState.meetupAgreements.single;
    expect(
      appState.respondMeetup(proposal.id, accept: true),
      contains('ผู้เสนอนัด'),
    );

    propose(
      pickupType: PickupType.suggestedSpot,
      placeLabel: 'ร้านสะดวกซื้อในย่านเมือง',
      spotLocation: appState.pickupPoints.first.location,
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
    );
    expect(
      appState.respondMeetup(proposal.id, accept: true),
      contains('ถูกตอบหรือเปลี่ยน'),
    );
    final latest = appState.meetupAgreements.last;
    appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
    expect(appState.respondMeetup(latest.id, accept: true), isNull);
    expect(
      appState.respondMeetup(latest.id, accept: false),
      contains('ถูกตอบหรือเปลี่ยน'),
    );
  });

  test('accepted meetup unlocks exact location only for that buyer', () {
    expect(appState.getExactLocationFor('prod_1', 'user_01'), isNull);
    expect(appState.shareExactAddress(conversationId), isNotNull);
    propose(
      pickupType: PickupType.sellerHome,
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
    );
    final proposal = appState.meetupAgreements.single;
    expect(proposal.spotLocation, isNull);
    appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
    expect(appState.shareExactAddress(conversationId), isNotNull);
    expect(appState.respondMeetup(proposal.id, accept: true), isNull);
    expect(
      appState.activeAgreementFor(conversationId)?.status,
      MeetupStatus.accepted,
    );
    expect(appState.meetupAgreements.single.spotLocation, isNull);
    expect(appState.shareExactAddress(conversationId), isNull);
    expect(
      appState.conversations.single.messages.last.type.name,
      'addressShare',
    );

    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    expect(appState.getExactLocationFor('prod_1', 'user_01'), isNotNull);
    expect(appState.getExactLocationFor('prod_2', 'user_01'), isNull);
    appState.signInVerifiedPhone('0800000003') == PhoneSignInResult.signedIn;
    expect(appState.getExactLocationFor('prod_1', 'user_03'), isNull);
  });

  test(
    'missing seller address asks for manual chat entry without sharing coords',
    () {
      appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
      final product = appState.addListing(
        title: 'Address omitted listing',
        description: '',
        price: 10,
        tradeFor: '',
        type: ListingType.sell,
        category: 'ของใช้ในบ้าน',
        condition: 'สภาพดี',
        exactLocation: appState.currentLocation,
        locationLabel: 'ย่านตัวอย่าง',
        exactAddress: '',
        pickupType: PickupType.sellerHome,
        imageUrl: '',
        productImages: [],
      );
      appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
      final conversation = appState.openConversationForProduct(product.id)!;
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
      appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
      expect(appState.respondMeetup(agreement.id, accept: true), isNull);
      final before = appState.conversations
          .firstWhere((item) => item.id == conversation.id)
          .messages
          .length;
      expect(
        appState.shareExactAddress(conversation.id),
        contains('พิมพ์ที่อยู่ในแชทด้วยตนเอง'),
      );
      final after = appState.conversations
          .firstWhere((item) => item.id == conversation.id)
          .messages;
      expect(after.length, before);
      expect(
        after.any((message) => message.type.name == 'addressShare'),
        isFalse,
      );
    },
  );

  test('unread count tracks all message types and clears when opened', () {
    final conversation = appState.conversations.single;
    expect(appState.unreadCountFor(conversation, 'user_02'), 0);
    appState.sendTextMessage(conversationId, 'สอบถามรายละเอียด');
    appState.sendImageMessage(conversationId, Uint8List.fromList([1, 2]));
    propose(
      pickupType: PickupType.sellerHome,
      scheduledAt: DateTime.now().add(const Duration(days: 1)),
    );
    final updated = appState.conversations.single;
    expect(appState.unreadCountFor(updated, 'user_02'), 3);
    appState.signInVerifiedPhone('0800000002') == PhoneSignInResult.signedIn;
    appState.markConversationRead(conversationId);
    expect(
      appState.unreadCountFor(appState.conversations.single, 'user_02'),
      0,
    );
  });
}
