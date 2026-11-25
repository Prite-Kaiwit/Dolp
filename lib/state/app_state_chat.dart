part of 'app_state.dart';

/// Conversations, messages, meetup agreements, and address sharing.
extension AppStateChat on AppState {
  ChatConversation? openConversationForProduct(String productId) {
    if (_expireSuspendedSession() != null) return null;
    if (!isLoggedIn) return null;
    final product = products.where((item) => item.id == productId).firstOrNull;
    if (product == null || product.sellerId == currentUser.id) return null;
    if (areUsersBlocked(currentUser.id, product.sellerId) ||
        (userById(product.sellerId)?.isSuspended ?? false)) {
      return null;
    }

    final existing = conversations.where(
      (conversation) =>
          conversation.productId == productId &&
          conversation.buyerId == currentUser.id &&
          conversation.sellerId == product.sellerId,
    );
    if (existing.isNotEmpty) return existing.first;

    final seller = users.firstWhere(
      (user) => user.id == product.sellerId,
      orElse: () => UserModel(id: product.sellerId, name: product.sellerName),
    );
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: _nextChatId('chat'),
      peerId: seller.id,
      peerName: seller.name,
      peerAvatar: seller.avatarUrl,
      buyerId: currentUser.id,
      sellerId: seller.id,
      productId: product.id,
      productTitle: product.title,
      productPrice: product.price,
      productImageUrl: product.imageUrl,
      productImage: product.coverImage,
      lastMessage: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
      lastMessageTime: now,
      unreadByUser: {currentUser.id: 0, seller.id: 0},
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

  int unreadCountFor(ChatConversation conversation, String userId) =>
      conversation.buyerId != userId && conversation.sellerId != userId
      ? 0
      : conversation.unreadByUser[userId] ??
            (conversation.buyerId == userId ? conversation.unreadCount : 0);

  List<ChatConversation> get conversationsForCurrentUser => isLoggedIn
      ? conversations.where(_isConversationParticipant).toList()
      : const [];

  UserModel? conversationPeer(ChatConversation conversation) {
    final peerId = currentUser.id == conversation.buyerId
        ? conversation.sellerId
        : conversation.buyerId;
    return users.where((user) => user.id == peerId).firstOrNull;
  }

  void markConversationRead(String conversationId) {
    final index = conversations.indexWhere((item) => item.id == conversationId);
    if (index == -1 || !_isConversationParticipant(conversations[index])) {
      return;
    }
    final conversation = conversations[index];
    final unread = Map<String, int>.of(conversation.unreadByUser)
      ..[currentUser.id] = 0;
    conversations[index] = conversation.copyWith(
      unreadCount: currentUser.id == conversation.buyerId
          ? 0
          : conversation.unreadCount,
      unreadByUser: unread,
    );
    notifications = notifications
        .map(
          (notification) =>
              notification.userId == currentUser.id &&
                  notification.type == AppNotificationType.newMessage &&
                  notification.refId == conversationId &&
                  !notification.isRead
              ? notification.copyWith(readAt: DateTime.now())
              : notification,
        )
        .toList();
    notifyListeners();
  }

  void ensureConversationSafetyMessage(String conversationId) {
    final conversation = conversations
        .where((item) => item.id == conversationId)
        .firstOrNull;
    if (conversation == null ||
        !_isConversationParticipant(conversation) ||
        conversation.messages.any(
          (message) => message.type == ChatMessageType.system,
        )) {
      return;
    }
    final messages = List<ChatMessage>.of(conversation.messages)
      ..insert(
        0,
        ChatMessage(
          id: 'safety_${conversation.id}',
          senderId: 'system',
          text: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
          timestamp: conversation.messages.isEmpty
              ? DateTime.now()
              : conversation.messages.first.timestamp,
          isMe: false,
          isSystemPrompt: true,
          type: ChatMessageType.system,
        ),
      );
    final index = conversations.indexWhere((item) => item.id == conversationId);
    conversations[index] = conversation.copyWith(messages: messages);
    notifyListeners();
  }

  String? sendTextMessage(String conversationId, String text) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งข้อความ';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'กรุณาพิมพ์ข้อความ';
    if (trimmed.length > kMaxChatMessageLength) {
      return 'ข้อความต้องไม่เกิน $kMaxChatMessageLength ตัวอักษร';
    }
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์ส่งข้อความ';
    if (areUsersBlocked(conversation.buyerId, conversation.sellerId)) {
      return 'ส่งข้อความไม่ได้เนื่องจากผู้ใช้บล็อกกัน';
    }
    _appendChatMessage(conversation, ChatMessageType.text, trimmed);
    return null;
  }

  String? sendImageMessage(String conversationId, Uint8List bytes) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งรูปภาพ';
    if (bytes.isEmpty) return 'ไม่พบข้อมูลรูปภาพ';
    if (bytes.lengthInBytes > kMaxChatImageBytes) {
      return 'รูปภาพต้องมีขนาดไม่เกิน 5 MB';
    }
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์ส่งรูปภาพ';
    if (areUsersBlocked(conversation.buyerId, conversation.sellerId)) {
      return 'ส่งรูปภาพไม่ได้เนื่องจากผู้ใช้บล็อกกัน';
    }
    _appendChatMessage(
      conversation,
      ChatMessageType.image,
      'ส่งรูปภาพ',
      image: ProductImageData.memory(bytes),
    );
    return null;
  }

  String? proposeMeetup({
    required String conversationId,
    required PickupType pickupType,
    required String placeLabel,
    required DateTime scheduledAt,
    String note = '',
    GeoLocation? spotLocation,
  }) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนเสนอนัดรับ';
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์เสนอนัด';
    if (areUsersBlocked(conversation.buyerId, conversation.sellerId)) {
      return 'เสนอนัดไม่ได้เนื่องจากผู้ใช้บล็อกกัน';
    }
    if (pickupType == PickupType.discussInChat) {
      return 'กรุณาเลือกวิธีนัดรับ';
    }
    final now = DateTime.now();
    if (!scheduledAt.isAfter(now) ||
        scheduledAt.isAfter(
          now.add(const Duration(days: kMeetupMaxDaysAhead)),
        )) {
      return 'วันนัดต้องอยู่ภายใน $kMeetupMaxDaysAhead วันข้างหน้า';
    }
    final product = products
        .where((item) => item.id == conversation.productId)
        .firstOrNull;
    if (product == null) return 'ไม่พบประกาศสินค้านี้';
    final label = pickupType == PickupType.sellerHome
        ? 'บ้านผู้ขาย (ย่าน ${product.locationLabel})'
        : placeLabel.trim();
    if (label.isEmpty) return 'กรุณาระบุสถานที่นัดรับ';
    if (label.length > kPlaceLabelMaxLength) {
      return 'ชื่อสถานที่ต้องไม่เกิน $kPlaceLabelMaxLength ตัวอักษร';
    }
    if (pickupType == PickupType.agreedSpot && spotLocation == null) {
      return 'กรุณาเลือกพิกัดของจุดที่ตกลงกัน';
    }
    if (note.trim().length > kMeetupNoteMaxLength) {
      return 'หมายเหตุต้องไม่เกิน $kMeetupNoteMaxLength ตัวอักษร';
    }
    final agreementId = _nextChatId('meetup');
    // Supersede only pending agreements; shared address messages remain history and are not resent.
    for (var index = 0; index < meetupAgreements.length; index++) {
      final old = meetupAgreements[index];
      if (old.conversationId == conversationId &&
          old.status == MeetupStatus.proposed) {
        meetupAgreements[index] = MeetupAgreement(
          id: old.id,
          conversationId: old.conversationId,
          productId: old.productId,
          proposerId: old.proposerId,
          responderId: old.responderId,
          pickupType: old.pickupType,
          placeLabel: old.placeLabel,
          spotLocation: old.spotLocation,
          scheduledAt: old.scheduledAt,
          note: old.note,
          status: MeetupStatus.superseded,
          createdAt: old.createdAt,
          respondedAt: now,
        );
      }
    }
    final agreement = MeetupAgreement(
      id: agreementId,
      conversationId: conversationId,
      productId: conversation.productId,
      proposerId: currentUser.id,
      responderId: currentUser.id == conversation.buyerId
          ? conversation.sellerId
          : conversation.buyerId,
      pickupType: pickupType,
      placeLabel: label,
      spotLocation: pickupType == PickupType.sellerHome ? null : spotLocation,
      scheduledAt: scheduledAt,
      note: note.trim(),
      status: MeetupStatus.proposed,
      createdAt: now,
    );
    meetupAgreements.add(agreement);
    _appendChatMessage(
      conversation,
      ChatMessageType.meetupProposal,
      'ข้อเสนอนัดรับ',
      meetupId: agreementId,
    );
    _notifyUser(
      userId: agreement.responderId,
      type: AppNotificationType.meetupProposed,
      title: 'มีข้อเสนอนัดรับใหม่',
      body: agreement.placeLabel,
      refType: 'chat',
      refId: conversation.id,
    );
    return null;
  }

  String? respondMeetup(String meetupId, {required bool accept}) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนตอบรับนัด';
    final index = meetupAgreements.indexWhere((item) => item.id == meetupId);
    if (index == -1) return 'ไม่พบข้อเสนอนัดรับ';
    final agreement = meetupAgreements[index];
    if (!_isConversationParticipantById(agreement.conversationId)) {
      return 'คุณไม่มีสิทธิ์ตอบข้อเสนอนี้';
    }
    final conversation = _participantConversation(agreement.conversationId)!;
    if (areUsersBlocked(conversation.buyerId, conversation.sellerId)) {
      return 'ตอบนัดไม่ได้เนื่องจากผู้ใช้บล็อกกัน';
    }
    if (agreement.status != MeetupStatus.proposed) {
      return 'ข้อเสนอนี้ถูกตอบหรือเปลี่ยนไปแล้ว';
    }
    if (agreement.proposerId == currentUser.id) {
      return 'ผู้เสนอนัดไม่สามารถตอบข้อเสนอของตัวเองได้';
    }
    if (agreement.responderId != currentUser.id) {
      return 'เฉพาะผู้รับข้อเสนอเท่านั้นที่ตอบได้';
    }
    meetupAgreements[index] = MeetupAgreement(
      id: agreement.id,
      conversationId: agreement.conversationId,
      productId: agreement.productId,
      proposerId: agreement.proposerId,
      responderId: agreement.responderId,
      pickupType: agreement.pickupType,
      placeLabel: agreement.placeLabel,
      spotLocation: agreement.pickupType == PickupType.sellerHome
          ? null
          : agreement.spotLocation,
      scheduledAt: agreement.scheduledAt,
      note: agreement.note,
      status: accept ? MeetupStatus.accepted : MeetupStatus.declined,
      createdAt: agreement.createdAt,
      respondedAt: DateTime.now(),
    );
    _appendChatMessage(
      conversation,
      ChatMessageType.system,
      accept ? 'ตกลงนัดรับแล้ว' : 'ปฏิเสธข้อเสนอนัดรับ',
    );
    _notifyUser(
      userId: agreement.proposerId,
      type: AppNotificationType.meetupResponded,
      title: accept ? 'ข้อเสนอนัดได้รับการตอบรับ' : 'ข้อเสนอนัดถูกปฏิเสธ',
      body: agreement.placeLabel,
      refType: 'chat',
      refId: conversation.id,
    );
    return null;
  }

  MeetupAgreement? activeAgreementFor(String conversationId) {
    final accepted = meetupAgreements.where(
      (item) =>
          item.conversationId == conversationId &&
          item.status == MeetupStatus.accepted,
    );
    if (accepted.isEmpty) return null;
    return accepted.reduce(
      (a, b) => a.respondedAt!.isAfter(b.respondedAt!) ? a : b,
    );
  }

  String? shareExactAddress(String conversationId) {
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งที่อยู่';
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์ส่งที่อยู่';
    if (areUsersBlocked(conversation.buyerId, conversation.sellerId)) {
      return 'ส่งที่อยู่ไม่ได้เนื่องจากผู้ใช้บล็อกกัน';
    }
    final product = products
        .where((item) => item.id == conversation.productId)
        .firstOrNull;
    if (product == null || product.sellerId != currentUser.id) {
      return 'เฉพาะเจ้าของประกาศเท่านั้นที่ส่งที่อยู่จริงได้';
    }
    final agreement = activeAgreementFor(conversationId);
    if (agreement == null) return 'ต้องมีนัดรับที่ตกลงแล้วก่อนส่งที่อยู่จริง';
    final privateLocation = _exactLocationsByProductId[product.id];
    if (privateLocation == null || privateLocation.address.trim().isEmpty) {
      return 'ผู้ขายยังไม่ได้บันทึกที่อยู่ กรุณาพิมพ์ที่อยู่ในแชทด้วยตนเอง';
    }
    final recipientId = agreement.proposerId == currentUser.id
        ? agreement.responderId
        : agreement.proposerId;
    _appendChatMessage(
      conversation,
      ChatMessageType.addressShare,
      privateLocation.address,
      recipientId: recipientId,
    );
    return null;
  }

  ChatConversation? _participantConversation(String conversationId) {
    if (!_isConversationParticipantById(conversationId)) return null;
    return conversations.firstWhere((item) => item.id == conversationId);
  }

  bool _isConversationParticipantById(String conversationId) {
    final conversation = conversations
        .where((item) => item.id == conversationId)
        .firstOrNull;
    return conversation != null && _isConversationParticipant(conversation);
  }

  bool _isConversationParticipant(ChatConversation conversation) =>
      currentUser.id == conversation.buyerId ||
      currentUser.id == conversation.sellerId;

  void _appendChatMessage(
    ChatConversation conversation,
    ChatMessageType type,
    String text, {
    ProductImageData? image,
    String? meetupId,
    String? recipientId,
  }) {
    final index = conversations.indexWhere(
      (item) => item.id == conversation.id,
    );
    final now = DateTime.now();
    final message = ChatMessage(
      id: _nextChatId('msg'),
      senderId: currentUser.id,
      text: text,
      timestamp: now,
      isMe: true,
      type: type,
      image: image,
      meetupId: meetupId,
      recipientId: recipientId,
    );
    final messages = List<ChatMessage>.of(conversation.messages)..add(message);
    final recipient =
        recipientId ??
        (currentUser.id == conversation.buyerId
            ? conversation.sellerId
            : conversation.buyerId);
    final unread = Map<String, int>.of(conversation.unreadByUser);
    unread[recipient] = (unread[recipient] ?? 0) + 1;
    conversations[index] = conversation.copyWith(
      messages: messages,
      lastMessage: type == ChatMessageType.image
          ? 'ส่งรูปภาพ'
          : type == ChatMessageType.meetupProposal
          ? 'ข้อเสนอนัดรับ'
          : text,
      lastMessageTime: now,
      unreadCount: conversation.unreadCount + 1,
      unreadByUser: unread,
    );
    if (type == ChatMessageType.text ||
        type == ChatMessageType.image ||
        type == ChatMessageType.addressShare) {
      _notifyUser(
        userId: recipient,
        type: AppNotificationType.newMessage,
        title: 'มีข้อความใหม่จาก ${currentUser.name}',
        body: 'มีข้อความใหม่ในแชท ${conversation.productTitle}',
        refType: 'chat',
        refId: conversation.id,
        aggregateKey: conversation.id,
      );
    }
    notifyListeners();
  }

  bool get shouldShowSafetyTips =>
      isLoggedIn && !_safetyTipsAcknowledgedBy.contains(currentUser.id);

  void acknowledgeSafetyTips() {
    if (!isLoggedIn) return;
    _safetyTipsAcknowledgedBy.add(currentUser.id);
    notifyListeners();
  }

  String _nextChatId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_chatSequence++}';
}
