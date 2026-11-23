import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/models/area_alert_subscription.dart';
import 'package:moor_market/models/chat.dart';
import 'package:moor_market/models/geo_location.dart';
import 'package:moor_market/models/meetup_agreement.dart';
import 'package:moor_market/models/nearby_product.dart';
import 'package:moor_market/models/notification.dart';
import 'package:moor_market/models/order.dart';
import 'package:moor_market/models/pickup_point.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/product_image_data.dart';
import 'package:moor_market/models/report.dart';
import 'package:moor_market/models/review.dart';
import 'package:moor_market/models/user.dart';

void main() {
  final timestamp = DateTime.utc(2026, 11, 23, 3, 10, 11, 120, 400);
  final image = ProductImageData.local(
    storageKey: 'sample.bin',
    bytes: Uint8List.fromList([1, 2, 3]),
  );
  final product = ProductModel(
    id: 'product-1',
    title: 'Used item',
    description: 'Description',
    price: 250,
    type: ListingType.trade,
    category: 'Other',
    condition: 'Good',
    publicLocation: GeoLocation(12.6, 102.1),
    locationLabel: 'Town',
    imageUrl: '',
    productImages: [image],
    sellerId: 'seller',
    sellerName: 'Seller',
    sellerAreaLabel: 'Town',
    status: ListingStatus.reserved,
    createdAt: timestamp,
  );

  test('all persisted models round-trip nested fields and UTC timestamps', () {
    final models =
        <(Map<String, Object?>, Object Function(Map<String, dynamic>))>[
          (product.toJson(), ProductModel.fromJson),
          (
            UserModel(
              id: 'member',
              name: 'Member',
              phone: '0800000000',
              homeLat: 12.6,
              homeLng: 102.1,
              role: UserRole.admin,
              createdAt: timestamp,
              isSuspended: true,
              suspensionReason: 'Review',
            ).toJson(),
            UserModel.fromJson,
          ),
          (
            OrderModel(
              id: 'order',
              buyerId: 'buyer',
              sellerId: 'seller',
              items: [
                OrderItemSnapshot(
                  productId: product.id,
                  title: product.title,
                  price: product.price,
                  coverImage: image,
                  listingType: ListingType.trade,
                ),
              ],
              totalPrice: 250,
              paymentMethod: PaymentMethod.transferOnHandover,
              pickupType: PickupType.agreedSpot,
              agreedPlaceLabel: 'Public place',
              agreedTime: timestamp,
              meetupId: 'meetup',
              handedOverAt: timestamp,
              completedAt: timestamp,
              createdAt: timestamp,
              status: OrderStatus.completed,
              events: [
                OrderEvent(
                  at: timestamp,
                  actorId: 'buyer',
                  status: OrderStatus.completed,
                ),
              ],
            ).toJson(),
            OrderModel.fromJson,
          ),
          (
            ChatMessage(
              id: 'message',
              senderId: 'buyer',
              text: 'Image',
              timestamp: timestamp,
              isMe: true,
              type: ChatMessageType.image,
              image: image,
            ).toJson(),
            ChatMessage.fromJson,
          ),
          (
            ChatConversation(
              id: 'conversation',
              peerId: 'seller',
              peerName: 'Seller',
              peerAvatar: '',
              productId: product.id,
              productTitle: product.title,
              productPrice: product.price,
              productImageUrl: '',
              productImage: image,
              buyerId: 'buyer',
              sellerId: 'seller',
              lastMessage: 'Hello',
              lastMessageTime: timestamp,
              unreadCount: 1,
              unreadByUser: const {'buyer': 1},
              messages: [
                ChatMessage(
                  id: 'message',
                  senderId: 'buyer',
                  text: 'Hello',
                  timestamp: timestamp,
                  isMe: true,
                ),
              ],
            ).toJson(),
            ChatConversation.fromJson,
          ),
          (
            MeetupAgreement(
              id: 'meetup',
              conversationId: 'conversation',
              productId: product.id,
              proposerId: 'buyer',
              responderId: 'seller',
              pickupType: PickupType.agreedSpot,
              placeLabel: 'Place',
              spotLocation: GeoLocation(12.7, 102.2),
              scheduledAt: timestamp,
              note: 'Note',
              status: MeetupStatus.accepted,
              createdAt: timestamp,
              respondedAt: timestamp,
            ).toJson(),
            MeetupAgreement.fromJson,
          ),
          (
            ReviewModel(
              id: 'review',
              orderId: 'order',
              reviewerId: 'buyer',
              revieweeId: 'seller',
              rating: 5,
              tags: const ['Friendly'],
              comment: 'Great',
              createdAt: timestamp,
            ).toJson(),
            ReviewModel.fromJson,
          ),
          (
            ReportModel(
              id: 'report',
              reporterId: 'buyer',
              reportedUserId: 'seller',
              orderId: 'order',
              reason: ReportReason.paymentScam,
              detail: 'Details',
              status: ReportStatus.actioned,
              createdAt: timestamp,
              adminId: 'admin',
              adminNote: 'Done',
              resolvedAt: timestamp,
            ).toJson(),
            ReportModel.fromJson,
          ),
          (
            AppNotification(
              id: 'notification',
              userId: 'buyer',
              type: AppNotificationType.orderStatusChanged,
              title: 'Order update',
              body: 'Completed',
              refType: 'order',
              refId: 'order',
              createdAt: timestamp,
              readAt: timestamp,
            ).toJson(),
            AppNotification.fromJson,
          ),
          (
            AreaAlertSubscription(
              userId: 'buyer',
              enabled: true,
              radiusKm: 3,
              categories: const ['Books'],
              center: GeoLocation(12.6, 102.1),
            ).toJson(),
            AreaAlertSubscription.fromJson,
          ),
          (
            SuggestedSpot(
              id: 'spot',
              name: 'Public place',
              description: 'Meet here',
              location: GeoLocation(12.6, 102.1),
              type: SuggestedSpotType.mall,
              isActive: false,
              openHours: '08:00-20:00',
            ).toJson(),
            SuggestedSpot.fromJson,
          ),
          (
            NearbyProduct(product: product, distanceKm: 2.5).toJson(),
            NearbyProduct.fromJson,
          ),
        ];

    for (final (json, decoder) in models) {
      final restored = decoder(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(jsonDecode(jsonEncode((restored as dynamic).toJson())), json);
    }
    expect(product.createdAt.isUtc, isTrue);
    expect(
      OrderModel.fromJson(
        jsonDecode(
              jsonEncode(
                OrderModel(
                  id: 'utc',
                  buyerId: 'buyer',
                  sellerId: 'seller',
                  items: const [],
                  totalPrice: 0,
                  paymentMethod: PaymentMethod.cashOnHandover,
                  pickupType: PickupType.discussInChat,
                  createdAt: timestamp,
                  status: OrderStatus.pending,
                  agreedTime: timestamp,
                ).toJson(),
              ),
            )
            as Map<String, dynamic>,
      ).agreedTime!.isUtc,
      isTrue,
    );
  });

  test('unknown enum values and missing fields use safe defaults', () {
    expect(
      ProductModel.fromJson({
        'id': 'old',
        'type': 'unrecognized',
        'status': 'unknown',
        'pickupType': 'unknown',
      }).type,
      ListingType.sell,
    );
    expect(
      ProductModel.fromJson({
        'id': 'old',
        'type': 'unrecognized',
        'status': 'unknown',
        'pickupType': 'unknown',
      }).status,
      ListingStatus.active,
    );
    expect(
      OrderModel.fromJson({'id': 'old', 'status': 'unknown'}).status,
      OrderStatus.pending,
    );
    expect(GeoLocation.fromJson({'lat': 999, 'lng': -999}), GeoLocation(0, 0));
  });

  test('product JSON excludes exact address and private coordinates', () {
    final json = jsonEncode(product.toJson());
    expect(json, isNot(contains('exactAddress')));
    expect(json, isNot(contains('exactLat')));
    expect(json, isNot(contains('exactLng')));
    expect(json, isNot(contains('privateLocation')));
    expect(json, isNot(contains('"bytes"')));
  });
}
