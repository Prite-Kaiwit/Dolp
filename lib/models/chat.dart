class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isSystemPrompt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isSystemPrompt = false,
  });
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
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
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
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
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
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
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
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }
}
