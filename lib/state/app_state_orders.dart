part of 'app_state.dart';

/// Cart, orders, handover, and reviews.
extension AppStateOrders on AppState {
  String? addToCart(ProductModel product) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนเพิ่มสินค้าลงตะกร้า';
    final actual = products.where((item) => item.id == product.id).firstOrNull;
    if (actual == null) return 'ไม่พบสินค้านี้';
    if (actual.sellerId == currentUser.id) {
      return 'เพิ่มประกาศของตัวเองลงตะกร้าไม่ได้';
    }
    if (areUsersBlocked(currentUser.id, actual.sellerId)) {
      return 'ไม่สามารถซื้อสินค้าจากผู้ใช้ที่บล็อกกันได้';
    }
    if (userById(actual.sellerId)?.isSuspended ?? false) {
      return 'ผู้ขายถูกระงับบัญชีชั่วคราว';
    }
    if (actual.status != ListingStatus.active) return 'สินค้านี้ไม่พร้อมขาย';
    if (cartItems.any((item) => item.id == actual.id)) return null;
    cartItems.add(actual);
    notifyListeners();
    return null;
  }

  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearCart() {
    cartItems.clear();
    notifyListeners();
  }

  String? cartItemUnavailableReason(ProductModel cartItem) {
    final current = products
        .where((product) => product.id == cartItem.id)
        .firstOrNull;
    if (current == null || current.status != ListingStatus.active) {
      return 'ไม่พร้อมขาย';
    }
    return null;
  }

  OrderCreationResult createOrderForSeller(
    String sellerId, {
    required PaymentMethod paymentMethod,
  }) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) {
      return OrderCreationResult.failure(sessionError);
    }
    if (!isLoggedIn) {
      return const OrderCreationResult.failure('เข้าสู่ระบบก่อนสั่งซื้อ');
    }
    final sellerCartItems = cartItems
        .where((item) => item.sellerId == sellerId)
        .toList();
    if (sellerCartItems.isEmpty) {
      return const OrderCreationResult.failure(
        'ไม่มีสินค้าของผู้ขายรายนี้ในตะกร้า',
      );
    }
    if (areUsersBlocked(currentUser.id, sellerId)) {
      return const OrderCreationResult.failure(
        'ไม่สามารถสั่งซื้อจากผู้ใช้ที่บล็อกกันได้',
      );
    }
    if (userById(sellerId)?.isSuspended ?? false) {
      return const OrderCreationResult.failure('บัญชีผู้ขายถูกระงับ');
    }

    final currentProducts = <ProductModel>[];
    for (final item in sellerCartItems) {
      final current = products
          .where((product) => product.id == item.id)
          .firstOrNull;
      if (current == null ||
          current.sellerId != sellerId ||
          current.status != ListingStatus.active) {
        return OrderCreationResult.failure(
          'สินค้า "${item.title}" ไม่พร้อมขายแล้ว กรุณานำออกจากตะกร้า',
        );
      }
      if (current.sellerId == currentUser.id) {
        return const OrderCreationResult.failure('ซื้อประกาศของตัวเองไม่ได้');
      }
      currentProducts.add(current);
    }

    final itemIds = currentProducts.map((item) => item.id).toSet();
    final meetup = acceptedMeetupForSeller(sellerId, itemIds);
    final now = DateTime.now();
    final order = OrderModel(
      id: 'ORD-${now.microsecondsSinceEpoch}-${_orderSequence++}',
      buyerId: currentUser.id,
      sellerId: sellerId,
      items: currentProducts
          .map(
            (product) => OrderItemSnapshot(
              productId: product.id,
              title: product.title,
              price: product.price,
              coverImage: product.coverImage,
              listingType: product.type,
            ),
          )
          .toList(growable: false),
      totalPrice: currentProducts.fold(
        0,
        (total, product) => total + product.price,
      ),
      paymentMethod: paymentMethod,
      pickupType: meetup?.pickupType ?? currentProducts.first.pickupType,
      agreedPlaceLabel: meetup?.placeLabel,
      agreedTime: meetup?.scheduledAt,
      meetupId: meetup?.id,
      createdAt: now,
      status: OrderStatus.pending,
      events: [
        OrderEvent(
          at: now,
          actorId: currentUser.id,
          status: OrderStatus.pending,
        ),
      ],
    );

    for (final product in currentProducts) {
      final index = products.indexWhere((item) => item.id == product.id);
      _reservedListingPreviousStatus[product.id] = product.status;
      products[index] = product.copyWith(status: ListingStatus.reserved);
    }
    orders.insert(0, order);
    cartItems.removeWhere((item) => item.sellerId == sellerId);
    _notifyUser(
      userId: sellerId,
      type: AppNotificationType.orderStatusChanged,
      title: 'มีคำสั่งซื้อใหม่',
      body: '${currentUser.displayName} ตกลงซื้อสินค้า ${order.items.length} รายการ',
      refType: 'order',
      refId: order.id,
    );
    notifyListeners();
    return OrderCreationResult.success(order);
  }

  MeetupAgreement? acceptedMeetupForSeller(
    String sellerId,
    Set<String> productIds,
  ) {
    final accepted =
        meetupAgreements.where((agreement) {
          if (agreement.status != MeetupStatus.accepted ||
              !productIds.contains(agreement.productId)) {
            return false;
          }
          final conversation = conversations
              .where((item) => item.id == agreement.conversationId)
              .firstOrNull;
          return conversation != null &&
              conversation.buyerId == currentUser.id &&
              conversation.sellerId == sellerId;
        }).toList()..sort((a, b) {
          final aAt = a.respondedAt ?? a.createdAt;
          final bAt = b.respondedAt ?? b.createdAt;
          return bAt.compareTo(aAt);
        });
    return accepted.firstOrNull;
  }

  String? markOrderHandedOver(String orderId) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn || currentUser.id != order.sellerId) {
      return 'เฉพาะผู้ขายของคำสั่งซื้อนี้เท่านั้นที่ยืนยันส่งมอบได้';
    }
    if (order.status != OrderStatus.pending) {
      return 'คำสั่งซื้อนี้ไม่ได้อยู่ในสถานะรอนัดรับ';
    }
    orders[index] = order.copyWith(handedOverAt: DateTime.now());
    notifyListeners();
    return null;
  }

  String? completeOrder(String orderId) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn || currentUser.id != order.buyerId) {
      return 'เฉพาะผู้ซื้อของคำสั่งซื้อนี้เท่านั้นที่ยืนยันรับสินค้าได้';
    }
    if (order.status != OrderStatus.pending) {
      return 'เปลี่ยนสถานะได้เฉพาะคำสั่งซื้อที่รอนัดรับ';
    }
    final now = DateTime.now();
    orders[index] = order.copyWith(
      status: OrderStatus.completed,
      completedAt: now,
      events: [
        ...order.events,
        OrderEvent(
          at: now,
          actorId: currentUser.id,
          status: OrderStatus.completed,
        ),
      ],
    );
    for (final item in order.items) {
      final productIndex = products.indexWhere((p) => p.id == item.productId);
      if (productIndex != -1) {
        products[productIndex] = products[productIndex].copyWith(
          status: ListingStatus.sold,
        );
      }
      _reservedListingPreviousStatus.remove(item.productId);
    }
    _incrementSuccessfulDeals(order);
    _notifyOrderParticipants(order, body: 'คำสั่งซื้อ ${order.id} สำเร็จแล้ว');
    notifyListeners();
    return null;
  }

  String? cancelOrder(String orderId, String reason) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn ||
        (currentUser.id != order.buyerId && currentUser.id != order.sellerId)) {
      return 'คุณไม่มีสิทธิ์ยกเลิกคำสั่งซื้อนี้';
    }
    if (order.status != OrderStatus.pending) {
      return 'ยกเลิกได้เฉพาะคำสั่งซื้อที่รอนัดรับ';
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) return 'กรุณาระบุเหตุผลในการยกเลิก';
    if (trimmedReason.length > 200) return 'เหตุผลต้องไม่เกิน 200 ตัวอักษร';
    final now = DateTime.now();
    orders[index] = order.copyWith(
      status: OrderStatus.cancelled,
      cancelledBy: currentUser.id,
      cancelReason: trimmedReason,
      cancelledAt: now,
      events: [
        ...order.events,
        OrderEvent(
          at: now,
          actorId: currentUser.id,
          status: OrderStatus.cancelled,
        ),
      ],
    );
    _restoreReservedProducts(order);
    _notifyOrderParticipants(order, body: 'คำสั่งซื้อ ${order.id} ถูกยกเลิก');
    notifyListeners();
    return null;
  }

  void _restoreReservedProducts(OrderModel order) {
    for (final item in order.items) {
      final index = products.indexWhere(
        (product) => product.id == item.productId,
      );
      if (index == -1) {
        _reservedListingPreviousStatus.remove(item.productId);
        continue;
      }
      if (products[index].status == ListingStatus.sold) {
        products[index] = products[index].copyWith(
          status: ListingStatus.active,
        );
        _reservedListingPreviousStatus.remove(item.productId);
        continue;
      }
      if (products[index].status != ListingStatus.reserved) {
        _reservedListingPreviousStatus.remove(item.productId);
        continue;
      }
      final previousStatus =
          _reservedListingPreviousStatus.remove(item.productId) ??
          ListingStatus.active;
      products[index] = products[index].copyWith(status: previousStatus);
    }
  }

  void _incrementSuccessfulDeals(OrderModel order) {
    users = users.map((user) {
      if (user.id == order.buyerId || user.id == order.sellerId) {
        return user.copyWith(successfulDeals: user.successfulDeals + 1);
      }
      return user;
    }).toList();
    currentUser =
        users.where((user) => user.id == currentUser.id).firstOrNull ??
        currentUser;
  }

  void _recalculateSuccessfulDeals() {
    final completedByUser = <String, int>{};
    for (final order in orders.where(
      (item) => item.status == OrderStatus.completed,
    )) {
      completedByUser.update(
        order.buyerId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      completedByUser.update(
        order.sellerId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    users = users
        .map(
          (user) =>
              user.copyWith(successfulDeals: completedByUser[user.id] ?? 0),
        )
        .toList();
    currentUser =
        users.where((user) => user.id == currentUser.id).firstOrNull ??
        currentUser;
  }

  UserModel? userById(String userId) =>
      users.where((user) => user.id == userId).firstOrNull;

  List<ReviewModel> reviewsForUser(String userId) {
    final result =
        reviews.where((review) => review.revieweeId == userId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  bool hasReviewedOrder(String orderId, String reviewerId) => reviews.any(
    (review) => review.orderId == orderId && review.reviewerId == reviewerId,
  );

  String? submitReview({
    required String orderId,
    required int rating,
    required List<String> tags,
    required String comment,
  }) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งรีวิว';
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null) return 'ไม่พบคำสั่งซื้อนี้';
    if (order.status != OrderStatus.completed) {
      return 'รีวิวได้หลังคำสั่งซื้อสำเร็จเท่านั้น';
    }
    if (currentUser.id != order.buyerId && currentUser.id != order.sellerId) {
      return 'คุณไม่ใช่ผู้ซื้อหรือผู้ขายของคำสั่งซื้อนี้';
    }
    if (hasReviewedOrder(orderId, currentUser.id)) {
      return 'คุณรีวิวคำสั่งซื้อนี้ไปแล้ว';
    }
    if (rating < 1 || rating > 5) return 'คะแนนต้องอยู่ระหว่าง 1 ถึง 5';
    if (comment.length > 500) return 'ความคิดเห็นต้องไม่เกิน 500 ตัวอักษร';
    final revieweeId = currentUser.id == order.buyerId
        ? order.sellerId
        : order.buyerId;
    reviews.add(
      ReviewModel(
        id: 'review_${DateTime.now().microsecondsSinceEpoch}',
        orderId: orderId,
        reviewerId: currentUser.id,
        revieweeId: revieweeId,
        rating: rating,
        tags: List.unmodifiable(tags),
        comment: comment.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _recalculateRatings();
    notifyListeners();
    return null;
  }

  ChatConversation? conversationForOrder(String orderId) {
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null ||
        (currentUser.id != order.buyerId && currentUser.id != order.sellerId)) {
      return null;
    }
    for (final item in order.items) {
      final existing = conversations
          .where(
            (conversation) =>
                conversation.productId == item.productId &&
                conversation.buyerId == order.buyerId &&
                conversation.sellerId == order.sellerId,
          )
          .firstOrNull;
      if (existing != null) return existing;
    }
    final product = products
        .where((item) => item.id == order.items.first.productId)
        .firstOrNull;
    if (product == null) return null;
    final buyer = userById(order.buyerId);
    final seller = userById(order.sellerId);
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: _nextChatId('chat'),
      peerId: currentUser.id == order.buyerId ? order.sellerId : order.buyerId,
      peerName: currentUser.id == order.buyerId
          ? seller?.displayName ?? product.sellerName
          : buyer?.displayName ?? 'ผู้ซื้อ',
      peerAvatar: currentUser.id == order.buyerId
          ? seller?.avatarUrl ?? ''
          : buyer?.avatarUrl ?? '',
      productId: product.id,
      productTitle: product.title,
      productPrice: product.price,
      productImageUrl: product.imageUrl,
      productImage: product.coverImage,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      lastMessage: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
      lastMessageTime: now,
      unreadByUser: {order.buyerId: 0, order.sellerId: 0},
      messages: [
        ChatMessage(
          id: _nextChatId('msg'),
          senderId: 'system',
          text: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
          timestamp: now,
          isMe: false,
          isSystemPrompt: true,
          type: ChatMessageType.system,
        ),
      ],
    );
    conversations.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  String? sharedAddressForOrder(String orderId) {
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null || currentUser.id != order.buyerId) return null;
    for (final item in order.items) {
      final conversation = conversations
          .where(
            (chat) =>
                chat.productId == item.productId &&
                chat.buyerId == order.buyerId &&
                chat.sellerId == order.sellerId,
          )
          .firstOrNull;
      if (conversation == null) continue;
      final address = conversation.messages
          .where(
            (message) =>
                message.type == ChatMessageType.addressShare &&
                message.recipientId == currentUser.id,
          )
          .lastOrNull;
      if (address != null) return address.text;
    }
    return null;
  }

  int get pendingOrderCount =>
      orders.where((order) => order.status == OrderStatus.pending).length;

  int get completedOrderCount =>
      orders.where((order) => order.status == OrderStatus.completed).length;
}
