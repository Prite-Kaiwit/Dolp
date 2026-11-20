// Legacy order fields are kept until the order-flow migration in phase 6.
// ignore_for_file: deprecated_member_use

import 'product.dart';

enum OrderStatus {
  // Legacy escrow states; remove or migrate in phase 6.
  escrowHolding, // ขั้น 1: พักเงินในระบบแล้ว
  pickupScheduled, // ขั้น 2: นัดหมายรับสินค้า ณ จุดนัดรับ
  buyerConfirmed, // ขั้น 3: ผู้ซื้อตรวจสอบและยืนยันรับสินค้า
  completed, // ขั้น 4: ปล่อยเงินโอนให้ผู้ขาย
  disputed, // ระงับ/ข้อพิพาท (Dispute)
  meetupProposed,
  meetupAccepted,
  handedOver,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get title {
    switch (this) {
      case OrderStatus.escrowHolding:
        return 'พักเงินในระบบ (Escrow Protected)';
      case OrderStatus.pickupScheduled:
        return 'รอนัดรับสินค้า ณ จุดนัดรับ';
      case OrderStatus.buyerConfirmed:
        return 'ผู้ซื้อยืนยันรับสินค้าแล้ว';
      case OrderStatus.completed:
        return 'ธุรกรรมสำเร็จ (โอนเงินให้ผู้ขายแล้ว)';
      case OrderStatus.disputed:
        return 'อยู่ระหว่างตรวจสอบข้อพิพาท (Dispute)';
      case OrderStatus.meetupProposed:
        return 'รอยืนยันนัดรับ';
      case OrderStatus.meetupAccepted:
        return 'ยืนยันนัดรับแล้ว';
      case OrderStatus.handedOver:
        return 'ส่งมอบสินค้าแล้ว';
      case OrderStatus.cancelled:
        return 'ยกเลิกคำสั่งซื้อ';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.escrowHolding:
        return 1;
      case OrderStatus.pickupScheduled:
        return 2;
      case OrderStatus.buyerConfirmed:
        return 3;
      case OrderStatus.completed:
        return 4;
      case OrderStatus.disputed:
        return -1;
      case OrderStatus.meetupProposed:
        return 1;
      case OrderStatus.meetupAccepted:
        return 2;
      case OrderStatus.handedOver:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }
}

class OrderModel {
  final String id;
  final String productId;
  final String productTitle;
  final double productPrice;
  final String productImageUrl;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  @Deprecated(
    'Use agreedPlaceLabel and pickupType instead; migrate in phase 6.',
  )
  final String pickupPoint;
  @Deprecated('Use agreedTime instead; migrate in phase 6.')
  final String scheduledTime;
  final PickupType pickupType;
  final String? agreedPlaceLabel;
  final DateTime? agreedTime;
  final String pickupNote;
  final String paymentMethod; // PromptPay / Mobile Banking
  final OrderStatus status;
  final DateTime createdAt;
  @Deprecated('Use pickupNote instead; migrate in phase 6.')
  final String note;

  OrderModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.productImageUrl,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.pickupPoint,
    required this.scheduledTime,
    this.pickupType = PickupType.discussInChat,
    String? agreedPlaceLabel,
    this.agreedTime,
    String? pickupNote,
    this.paymentMethod = 'PromptPay',
    this.status = OrderStatus.escrowHolding,
    DateTime? createdAt,
    this.note = '',
  }) : agreedPlaceLabel = agreedPlaceLabel ?? pickupPoint,
       pickupNote = pickupNote ?? note,
       createdAt = createdAt ?? DateTime.now();

  OrderModel copyWith({
    String? id,
    String? productId,
    String? productTitle,
    double? productPrice,
    String? productImageUrl,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? sellerName,
    String? pickupPoint,
    String? scheduledTime,
    PickupType? pickupType,
    String? agreedPlaceLabel,
    DateTime? agreedTime,
    String? pickupNote,
    String? paymentMethod,
    OrderStatus? status,
    DateTime? createdAt,
    String? note,
  }) {
    return OrderModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productPrice: productPrice ?? this.productPrice,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      pickupType: pickupType ?? this.pickupType,
      agreedPlaceLabel: agreedPlaceLabel ?? this.agreedPlaceLabel,
      agreedTime: agreedTime ?? this.agreedTime,
      pickupNote: pickupNote ?? note ?? this.pickupNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }
}
