import 'product.dart';
import 'product_image_data.dart';

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

  const OrderCreationResult.success(OrderModel value)
    : this._(order: value);

  const OrderCreationResult.failure(String reason) : this._(error: reason);

  bool get isSuccess => order != null;
}

enum ReportResolution { close, cancelOrder, accountSuspended }
