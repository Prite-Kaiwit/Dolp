import 'package:flutter/foundation.dart';

import 'product_image_data.dart';
import '../utils/json_helpers.dart';

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

  Map<String, Object?> toJson() => {
    'id': id,
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'isMe': isMe,
    'isSystemPrompt': isSystemPrompt,
    'type': type.name,
    'image': image?.toJson(),
    'meetupId': meetupId,
    'recipientId': recipientId,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    var type = jsonEnum(
      ChatMessageType.values,
      json['type'],
      ChatMessageType.text,
    );
    final image = json['image'] is Map
        ? ProductImageData.fromJson(jsonObject(json['image']))
        : null;
    final meetupId = json['meetupId'] is String
        ? json['meetupId'] as String
        : null;
    if ((type == ChatMessageType.image && image == null) ||
        (type == ChatMessageType.meetupProposal && meetupId == null)) {
      type = ChatMessageType.text;
    }
    return ChatMessage(
      id: jsonString(json['id'], 'missing-message'),
      senderId: jsonString(json['senderId']),
      text: jsonString(json['text']),
      timestamp: jsonDateTime(json['timestamp']),
      isMe: jsonBool(json['isMe']),
      isSystemPrompt: jsonBool(json['isSystemPrompt']),
      type: type,
      image: image,
      meetupId: meetupId,
      recipientId: json['recipientId'] is String
          ? json['recipientId'] as String
          : null,
    );
  }
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

  /// A chat with a shop that is not about any specific listing.
  bool get isShopInquiry => productId.isEmpty;

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

  Map<String, Object?> toJson() => {
    'id': id,
    'peerId': peerId,
    'peerName': peerName,
    'peerAvatar': peerAvatar,
    'productId': productId,
    'productTitle': productTitle,
    'productPrice': productPrice,
    'productImageUrl': productImageUrl,
    'productImage': productImage?.toJson(),
    'buyerId': buyerId,
    'sellerId': sellerId,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime.toUtc().toIso8601String(),
    'unreadCount': unreadCount,
    'unreadByUser': unreadByUser,
    'messages': messages.map((message) => message.toJson()).toList(),
  };

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: jsonString(json['id'], 'missing-conversation'),
        peerId: jsonString(json['peerId']),
        peerName: jsonString(json['peerName'], 'ผู้ใช้'),
        peerAvatar: jsonString(json['peerAvatar']),
        productId: jsonString(json['productId']),
        productTitle: jsonString(json['productTitle'], 'สินค้า'),
        productPrice: jsonDouble(json['productPrice']),
        productImageUrl: jsonString(json['productImageUrl']),
        productImage: json['productImage'] is Map
            ? ProductImageData.fromJson(jsonObject(json['productImage']))
            : null,
        buyerId: jsonString(json['buyerId']),
        sellerId: jsonString(json['sellerId']),
        lastMessage: jsonString(json['lastMessage']),
        lastMessageTime: jsonDateTime(json['lastMessageTime']),
        unreadCount: jsonInt(json['unreadCount']),
        unreadByUser: {
          for (final entry in jsonObject(json['unreadByUser']).entries)
            if (entry.value is num) entry.key: (entry.value as num).toInt(),
        },
        messages: jsonList(
          json['messages'],
        ).map((message) => ChatMessage.fromJson(jsonObject(message))).toList(),
      );
}
