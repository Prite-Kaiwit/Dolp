import 'product.dart';
import 'product_image_data.dart';
import '../utils/json_helpers.dart';

enum OrderStatus { pending, completed, cancelled, disputed }

extension OrderStatusExtension on OrderStatus {
  String get title {
    switch (this) {
      case OrderStatus.pending:
        return 'รอนัดรับ';
      case OrderStatus.completed:
        return 'สำเร็จ';
      case OrderStatus.cancelled:
        return 'ยกเลิก';
      case OrderStatus.disputed:
        return 'รอตรวจสอบปัญหา';
    }
  }
}

enum PaymentMethod { cashOnHandover, transferOnHandover }

extension PaymentMethodExtension on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cashOnHandover:
        return 'เงินสดหน้างาน';
      case PaymentMethod.transferOnHandover:
        return 'โอนตอนรับของ';
    }
  }
}

class OrderItemSnapshot {
  final String productId;
  final String title;
  final double price;
  final ProductImageData? coverImage;
  final ListingType listingType;

  const OrderItemSnapshot({
    required this.productId,
    required this.title,
    required this.price,
    required this.coverImage,
    required this.listingType,
  });

  Map<String, Object?> toJson() => {
    'productId': productId,
    'title': title,
    'price': price,
    'coverImage': coverImage?.toJson(),
    'listingType': listingType.name,
  };

  factory OrderItemSnapshot.fromJson(Map<String, dynamic> json) =>
      OrderItemSnapshot(
        productId: jsonString(json['productId']),
        title: jsonString(json['title'], 'สินค้า'),
        price: jsonDouble(json['price']),
        coverImage: json['coverImage'] is Map
            ? ProductImageData.fromJson(jsonObject(json['coverImage']))
            : null,
        listingType: jsonEnum(
          ListingType.values,
          json['listingType'],
          ListingType.sell,
        ),
      );
}

class OrderEvent {
  final DateTime at;
  final String actorId;
  final OrderStatus status;

  const OrderEvent({
    required this.at,
    required this.actorId,
    required this.status,
  });

  Map<String, Object> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'actorId': actorId,
    'status': status.name,
  };

  factory OrderEvent.fromJson(Map<String, dynamic> json) => OrderEvent(
    at: jsonDateTime(json['at']),
    actorId: jsonString(json['actorId']),
    status: jsonEnum(OrderStatus.values, json['status'], OrderStatus.pending),
  );
}

class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final List<OrderItemSnapshot> items;
  final double totalPrice;
  final PaymentMethod paymentMethod;
  final PickupType pickupType;
  final String? agreedPlaceLabel;
  final DateTime? agreedTime;
  final String? meetupId;
  final DateTime? handedOverAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final OrderStatus status;
  final String? cancelledBy;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final OrderStatus? previousStatus;
  final List<OrderEvent> events;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.pickupType,
    required this.createdAt,
    required this.status,
    this.agreedPlaceLabel,
    this.agreedTime,
    this.meetupId,
    this.handedOverAt,
    this.completedAt,
    this.cancelledBy,
    this.cancelReason,
    this.cancelledAt,
    this.previousStatus,
    this.events = const [],
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'items': items.map((item) => item.toJson()).toList(),
    'totalPrice': totalPrice,
    'paymentMethod': paymentMethod.name,
    'pickupType': pickupType.name,
    'agreedPlaceLabel': agreedPlaceLabel,
    'agreedTime': agreedTime?.toUtc().toIso8601String(),
    'meetupId': meetupId,
    'handedOverAt': handedOverAt?.toUtc().toIso8601String(),
    'completedAt': completedAt?.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'status': status.name,
    'cancelledBy': cancelledBy,
    'cancelReason': cancelReason,
    'cancelledAt': cancelledAt?.toUtc().toIso8601String(),
    'previousStatus': previousStatus?.name,
    'events': events.map((event) => event.toJson()).toList(),
  };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: jsonString(json['id'], 'missing-order'),
    buyerId: jsonString(json['buyerId']),
    sellerId: jsonString(json['sellerId']),
    items: jsonList(
      json['items'],
    ).map((item) => OrderItemSnapshot.fromJson(jsonObject(item))).toList(),
    totalPrice: jsonDouble(json['totalPrice']),
    paymentMethod: jsonEnum(
      PaymentMethod.values,
      json['paymentMethod'],
      PaymentMethod.cashOnHandover,
    ),
    pickupType: jsonEnum(
      PickupType.values,
      json['pickupType'],
      PickupType.discussInChat,
    ),
    agreedPlaceLabel: json['agreedPlaceLabel'] is String
        ? json['agreedPlaceLabel'] as String
        : null,
    agreedTime: jsonNullableDateTime(json['agreedTime']),
    meetupId: json['meetupId'] is String ? json['meetupId'] as String : null,
    handedOverAt: jsonNullableDateTime(json['handedOverAt']),
    completedAt: jsonNullableDateTime(json['completedAt']),
    createdAt: jsonDateTime(json['createdAt']),
    status: jsonEnum(OrderStatus.values, json['status'], OrderStatus.pending),
    cancelledBy: json['cancelledBy'] is String
        ? json['cancelledBy'] as String
        : null,
    cancelReason: json['cancelReason'] is String
        ? json['cancelReason'] as String
        : null,
    cancelledAt: jsonNullableDateTime(json['cancelledAt']),
    previousStatus: json['previousStatus'] == null
        ? null
        : jsonEnum(
            OrderStatus.values,
            json['previousStatus'],
            OrderStatus.pending,
          ),
    events: jsonList(
      json['events'],
    ).map((event) => OrderEvent.fromJson(jsonObject(event))).toList(),
  );

  OrderModel copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    List<OrderItemSnapshot>? items,
    double? totalPrice,
    PaymentMethod? paymentMethod,
    PickupType? pickupType,
    String? agreedPlaceLabel,
    DateTime? agreedTime,
    String? meetupId,
    DateTime? handedOverAt,
    DateTime? completedAt,
    DateTime? createdAt,
    OrderStatus? status,
    String? cancelledBy,
    String? cancelReason,
    DateTime? cancelledAt,
    OrderStatus? previousStatus,
    bool clearPreviousStatus = false,
    List<OrderEvent>? events,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      pickupType: pickupType ?? this.pickupType,
      agreedPlaceLabel: agreedPlaceLabel ?? this.agreedPlaceLabel,
      agreedTime: agreedTime ?? this.agreedTime,
      meetupId: meetupId ?? this.meetupId,
      handedOverAt: handedOverAt ?? this.handedOverAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      previousStatus: clearPreviousStatus
          ? null
          : previousStatus ?? this.previousStatus,
      events: events ?? this.events,
    );
  }
}

class OrderCreationResult {
  final OrderModel? order;
  final String? error;

  const OrderCreationResult._({this.order, this.error});

  const OrderCreationResult.success(OrderModel value) : this._(order: value);

  const OrderCreationResult.failure(String reason) : this._(error: reason);

  bool get isSuccess => order != null;
}

enum ReportResolution { close, cancelOrder, accountSuspended }
