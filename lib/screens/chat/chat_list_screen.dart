import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อความแชท'),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          if (appState.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.pinkPale,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.pinkPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ยังไม่มีการสนทนา',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.inkText),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'กดปุ่ม "แชท" จากหน้ารายละเอียดสินค้าเพื่อสอบถามผู้ขาย',
                    style: TextStyle(fontSize: 13, color: AppColors.graySecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: appState.conversations.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final conv = appState.conversations[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(conversation: conv),
                    ),
                  );
                },
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(conv.peerAvatar),
                      onBackgroundImageError: (_, _) {},
                      child: Text(
                        conv.peerName.isNotEmpty ? conv.peerName[0] : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Product mini badge
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.pinkPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.shopping_bag, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        conv.peerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatTime(conv.lastMessageTime),
                      style: const TextStyle(fontSize: 11, color: AppColors.graySecondary),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.pinkPale,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            conv.productTitle,
                            style: const TextStyle(fontSize: 10, color: AppColors.pinkDark, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '฿${conv.productPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.inkText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conv.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: conv.unreadCount > 0 ? AppColors.inkText : AppColors.graySecondary,
                        fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: conv.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.pinkPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${conv.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} น.';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ชม.';
    } else {
      return '${diff.inDays} วัน';
    }
  }
}
