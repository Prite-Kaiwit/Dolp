import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../models/product.dart';
import '../../utils/distance.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../order/pickup_point_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatRoomScreen({super.key, required this.conversation});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickResponses = [
    'สินค้านี้ยังอยู่ไหมครับ?',
    'สะดวกนัดรับที่จุดสาธารณะในพื้นที่ไหมครับ?',
    'ของแท้ สภาพตามรูปเลยใช่ไหมครับ?',
    'ตกลงครับ เดี๋ยวชำระเงินผ่าน Escrow ให้ครับ',
  ];

  void _sendMessage([String? messageText]) {
    final text = (messageText ?? _textController.text).trim();
    if (text.isEmpty) return;

    AppState().sendChatMessage(widget.conversation.id, text);
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.conversation.peerAvatar),
              onBackgroundImageError: (_, _) {},
              child: Text(
                widget.conversation.peerName.isNotEmpty
                    ? widget.conversation.peerName[0]
                    : 'U',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.peerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: AppColors.greenPrimary,
                        size: 8,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ออนไลน์ (ยืนยันตัวตนแล้ว)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.graySecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pinned Product Banner with Escrow Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: const Border(
                  bottom: BorderSide(color: AppColors.grayLine),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.conversation.productImageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.pinkPale,
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.conversation.productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '฿${widget.conversation.productPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.pinkPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Lookup product or create stub
                      final product = appState.products.firstWhere(
                        (p) => p.id == widget.conversation.productId,
                        orElse: () => ProductModel(
                          id: widget.conversation.productId,
                          title: widget.conversation.productTitle,
                          description: '',
                          price: widget.conversation.productPrice,
                          type: ListingType.sell,
                          category: 'ทั่วไป',
                          condition: 'สภาพดี',
                          publicLocation: obfuscate(
                            appState.currentLocation,
                            widget.conversation.productId,
                          ),
                          locationLabel: 'อำเภอเมืองจันทบุรี',
                          pickupPoint: 'จุดสาธารณะตัวอย่าง เขตเมือง',
                          imageUrl: widget.conversation.productImageUrl,
                          sellerId: widget.conversation.peerId,
                          sellerName: widget.conversation.peerName,
                          sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PickupPointScreen(product: product),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      backgroundColor: AppColors.greenPrimary,
                    ),
                    child: const Text(
                      'สั่งซื้อ Escrow',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Messages View
            Expanded(
              child: ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  final activeConv = appState.conversations.firstWhere(
                    (c) => c.id == widget.conversation.id,
                    orElse: () => widget.conversation,
                  );

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: activeConv.messages.length,
                    itemBuilder: (context, index) {
                      final msg = activeConv.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  );
                },
              ),
            ),

            // Quick Response Chips
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickResponses.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        _quickResponses[index],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkText,
                        ),
                      ),
                      backgroundColor: AppColors.grayBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.grayLine),
                      ),
                      onPressed: () => _sendMessage(_quickResponses[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: AppColors.grayLine)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.graySecondary,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เลือกรูปภาพจำลอง')),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.grayBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.grayLine),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'พิมพ์ข้อความของคุณที่นี่...',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _sendMessage(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.pinkPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(widget.conversation.peerAvatar),
              onBackgroundImageError: (_, _) {},
              child: Text(
                widget.conversation.peerName[0],
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.pinkPrimary : AppColors.grayBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AppColors.grayLine),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.inkText,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
