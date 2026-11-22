import 'package:flutter/foundation.dart';

import 'product_image_data.dart';

enum ChatMessageType { text, image, meetupProposal, addressShare, system }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isSystemPrompt;
  final ChatMessageType type;
  final ProductImageData? image;
  final String? meetupId;
  final String? recipientId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isSystemPrompt = false,
    this.type = ChatMessageType.text,
    this.image,
    this.meetupId,
    this.recipientId,
  }) : assert(type != ChatMessageType.image || image != null),
       assert(type != ChatMessageType.meetupProposal || meetupId != null);

  Uint8List? get imageBytes => image?.bytes;
}

class ChatConversation {
  final String id;
  final String peerId;
  final String peerName;
  final String peerAvatar;
  final String productId;
  final String productTitle;
  final double productPrice;
  final String productImageUrl;
  final ProductImageData? productImage;
  final String buyerId;
  final String sellerId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final Map<String, int> unreadByUser;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerAvatar,
    required this.productId,
    required this.productTitle,
    required this.productPrice,
    required this.productImageUrl,
    this.productImage,
    this.buyerId = '',
    this.sellerId = '',
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.unreadByUser = const {},
    required this.messages,
  });

  ChatConversation copyWith({
    String? id,
    String? peerId,
    String? peerName,
    String? peerAvatar,
    String? productId,
    String? productTitle,
    double? productPrice,
    String? productImageUrl,
    ProductImageData? productImage,
    String? buyerId,
    String? sellerId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    Map<String, int>? unreadByUser,
    List<ChatMessage>? messages,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerAvatar: peerAvatar ?? this.peerAvatar,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productPrice: productPrice ?? this.productPrice,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productImage: productImage ?? this.productImage,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadByUser: unreadByUser ?? this.unreadByUser,
      messages: messages ?? this.messages,
    );
  }
}
