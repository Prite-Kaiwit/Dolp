import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/chat_limits.dart';
import '../../models/chat.dart';
import '../../models/meetup_agreement.dart';
import '../../models/product.dart';
import '../../screens/review_safety/report_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../utils/meetup_sharing.dart';
import '../../widgets/product_image.dart';
import '../../widgets/safety_tips_sheet.dart';
import 'meetup_options_screen.dart';
import '../profile/public_user_profile_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatRoomScreen({super.key, required this.conversation});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _quickResponses = const [
    'สินค้านี้ยังอยู่ไหมครับ?',
    'สะดวกนัดรับที่จุดสาธารณะในพื้นที่ไหมครับ?',
    'ของแท้ สภาพตามรูปเลยใช่ไหมครับ?',
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    AppState().ensureConversationSafetyMessage(widget.conversation.id);
    AppState().markConversationRead(widget.conversation.id);
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_onTextChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _sendMessage([String? messageText]) {
    final appState = AppState();
    final error = appState.sendTextMessage(
      widget.conversation.id,
      messageText ?? _textController.text,
    );
    if (error != null) {
      _showMessage(error);
      return;
    }
    if (messageText == null) _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final conversation = appState.conversations.firstWhere(
          (item) => item.id == widget.conversation.id,
          orElse: () => widget.conversation,
        );
        final peer = appState.conversationPeer(conversation);
        final peerName = peer?.name ?? conversation.peerName;
        final peerAvatar = peer?.avatarUrl ?? conversation.peerAvatar;
        final peerUserId = appState.currentUser.id == conversation.buyerId
            ? conversation.sellerId
            : conversation.buyerId;
        if (!appState.isLoggedIn ||
            (appState.currentUser.id != conversation.buyerId &&
                appState.currentUser.id != conversation.sellerId)) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: Text('เข้าสู่ระบบเพื่อเปิดบทสนทนานี้')),
            ),
          );
        }
        final product = appState.products
            .where((item) => item.id == conversation.productId)
            .firstOrNull;
        final agreement = appState.activeAgreementFor(conversation.id);
        final blocked = appState.isBlocked(peerUserId);

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(peerAvatar),
                  onBackgroundImageError: (_, _) {},
                  child: Text(peerName.isNotEmpty ? peerName[0] : 'U'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PublicUserProfileScreen(
                          userId: peerUserId,
                        ),
                      ),
                    ),
                    child: Text(
                      peerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'ตัวเลือกแชท',
                onSelected: (value) {
                  if (value == 'profile') {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PublicUserProfileScreen(
                          userId: peerUserId,
                        ),
                      ),
                    );
                  } else if (value == 'report') {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ReportScreen(
                          targetUserId: peerUserId,
                          targetName: peerName,
                          productId: conversation.productId,
                        ),
                      ),
                    );
                  } else if (value == 'block') {
                    final error = appState.blockUser(peerUserId);
                    _showMessage(error ?? 'บล็อกผู้ใช้แล้ว');
                  } else if (value == 'safety') {
                    showSafetyTipsSheet(context, force: true);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Text('ดูโปรไฟล์ผู้ใช้'),
                  ),
                  const PopupMenuItem(value: 'report', child: Text('รายงานผู้ใช้')),
                  if (!appState.isBlocked(peerUserId))
                    const PopupMenuItem(value: 'block', child: Text('บล็อกผู้ใช้')),
                  const PopupMenuItem(
                    value: 'safety',
                    child: Text('คำแนะนำก่อนนัดรับ'),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildProductSummary(conversation, product, agreement),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(
                      conversation.messages[index],
                      peerName,
                      peerAvatar,
                    ),
                  ),
                ),
                if (blocked)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'แชทนี้ยังเปิดอ่านได้ แต่ส่งข้อความไม่ได้เนื่องจากผู้ใช้บล็อกกัน',
                      style: TextStyle(color: AppColors.warningDark),
                    ),
                  ),
                if (!blocked && _quickResponses.isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _quickResponses
                          .map(
                            (response) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  response,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onPressed: () => _sendMessage(response),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (!blocked) _buildInputBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductSummary(
    ChatConversation conversation,
    ProductModel? product,
    MeetupAgreement? agreement,
  ) {
    final appState = AppState();
    final distance = product == null
        ? null
        : distanceKm(appState.currentLocation, product.publicLocation);
    final isSeller = product?.sellerId == appState.currentUser.id;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.grayLine)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: ProductImage(
                    source: conversation.productImage,
                    fallbackUrl: conversation.productImageUrl,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.productTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      conversation.productPrice == 0
                          ? 'ฟรี'
                          : '฿${conversation.productPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.oceanBlue,
                        fontSize: 13,
                      ),
                    ),
                    if (distance != null)
                      Text(
                        formatDistance(distance),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.graySecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (product != null)
                OutlinedButton(
                  onPressed: () => showMeetupOptionsSheet(
                    context,
                    conversation: conversation,
                    product: product,
                  ),
                  child: const Text('นัดรับ'),
                ),
            ],
          ),
          if (agreement != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'นัดหมาย: ${agreement.placeLabel} · ${_formatDateTime(context, agreement.scheduledAt)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        final appState = AppState();
                        await shareMeetupAgreement(
                          agreement: agreement,
                          partnerName: appState
                                  .userById(conversation.peerId)
                                  ?.name ??
                              conversation.peerName,
                          productTitle: conversation.productTitle,
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('แชร์แผนนัด'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isSeller && agreement != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const ValueKey('share-exact-address'),
                onPressed: () => _confirmShareAddress(conversation),
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('ส่งที่อยู่จริง'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final trimmed = _textController.text.trim();
    final remaining = kMaxChatMessageLength - _textController.text.length;
    final showCount = remaining <= 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.grayLine)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'แนบรูปภาพ',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: _showImageSourceOptions,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              maxLength: kMaxChatMessageLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => showCount
                  ? Text(
                      'เหลือ $remaining ตัวอักษร',
                      style: TextStyle(
                        fontSize: 10,
                        color: remaining < 0
                            ? AppColors.error
                            : AppColors.graySecondary,
                      ),
                    )
                  : null,
              decoration: const InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(22)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            tooltip: 'ส่งข้อความ',
            onPressed: trimmed.isEmpty ? null : () => _sendMessage(),
            icon: const Icon(Icons.send_rounded, color: AppColors.oceanBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    String peerName,
    String peerAvatar,
  ) {
    if (message.recipientId != null &&
        message.recipientId != AppState().currentUser.id &&
        message.senderId != AppState().currentUser.id) {
      return const SizedBox.shrink();
    }
    if (message.type == ChatMessageType.system || message.isSystemPrompt) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.grayBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.graySecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    final isMe = message.senderId == AppState().currentUser.id;
    if (message.type == ChatMessageType.meetupProposal) {
      return _buildMeetupMessage(message, isMe);
    }

    final content = switch (message.type) {
      ChatMessageType.image => _buildImageMessage(message),
      ChatMessageType.addressShare => _buildAddressMessage(message),
      _ => Text(
        message.text,
        style: TextStyle(
          color: isMe ? Colors.white : AppColors.deepNavy,
          fontSize: 14,
        ),
      ),
    };

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
              backgroundImage: NetworkImage(peerAvatar),
              onBackgroundImageError: (_, _) {},
              child: Text(
                peerName.isNotEmpty ? peerName[0] : 'U',
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: message.type == ChatMessageType.addressShare
                    ? AppColors.success
                    : isMe
                    ? AppColors.oceanBlue
                    : AppColors.grayBg,
                borderRadius: BorderRadius.circular(16),
                border: isMe ? null : Border.all(color: AppColors.grayLine),
              ),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetupMessage(ChatMessage message, bool isMe) {
    final agreement = AppState().meetupAgreements
        .where((item) => item.id == message.meetupId)
        .firstOrNull;
    if (agreement == null) return const SizedBox.shrink();
    final canRespond =
        !isMe &&
        agreement.status == MeetupStatus.proposed &&
        agreement.responderId == AppState().currentUser.id;
    final isFinal = agreement.status != MeetupStatus.proposed;
    return Opacity(
      opacity:
          agreement.status == MeetupStatus.superseded ||
              agreement.status == MeetupStatus.declined
          ? 0.62
          : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_available_outlined),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'ข้อเสนอนัดรับ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          _statusLabel(agreement.status),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('วิธีรับ: ${agreement.pickupType.label}'),
                    Text('สถานที่: ${agreement.placeLabel}'),
                    Text(
                      'เวลา: ${_formatDateTime(context, agreement.scheduledAt)}',
                    ),
                    if (agreement.note.isNotEmpty)
                      Text('หมายเหตุ: ${agreement.note}'),
                    if (canRespond) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _respondMeetup(agreement, accept: true),
                              child: const Text('ตกลง'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _respondMeetup(agreement, accept: false),
                              child: const Text('ขอเปลี่ยน'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isFinal && agreement.status == MeetupStatus.accepted)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('นัดหมายนี้ได้รับการยืนยันแล้ว'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessage(ChatMessage message) {
    final image = message.image;
    if (image?.bytes == null) return const Text('ไม่สามารถแสดงรูปภาพได้');
    return GestureDetector(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(),
            body: Center(
              child: InteractiveViewer(child: ProductImage(source: image)),
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: 220,
        height: 180,
        child: ProductImage(source: image),
      ),
    );
  }

  Widget _buildAddressMessage(ChatMessage message) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        message.text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      TextButton.icon(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: message.text));
          if (mounted) _showMessage('คัดลอกที่อยู่แล้ว');
        },
        icon: const Icon(Icons.copy, color: Colors.white, size: 16),
        label: const Text('คัดลอก', style: TextStyle(color: Colors.white)),
      ),
    ],
  );

  Future<void> _respondMeetup(
    MeetupAgreement agreement, {
    required bool accept,
  }) async {
    final error = AppState().respondMeetup(agreement.id, accept: accept);
    if (error != null) {
      _showMessage(error);
      return;
    }
    if (accept) {
      await showSafetyTipsSheet(context);
    } else {
      final appState = AppState();
      final conversation = appState.conversations.firstWhere(
        (item) => item.id == agreement.conversationId,
      );
      final product = appState.products.firstWhere(
        (item) => item.id == agreement.productId,
      );
      await showMeetupOptionsSheet(
        context,
        conversation: conversation,
        product: product,
      );
    }
  }

  Future<void> _confirmShareAddress(ChatConversation conversation) async {
    final peer = AppState().conversationPeer(conversation);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ส่งที่อยู่จริง?'),
        content: Text(
          'ที่อยู่นี้จะถูกส่งให้ ${peer?.name ?? conversation.peerName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ส่งที่อยู่'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = AppState().shareExactAddress(conversation.id);
    if (error != null) _showMessage(error);
  }

  Future<void> _showImageSourceOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกจากคลังรูป'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('ถ่ายภาพ'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final error = AppState().sendImageMessage(widget.conversation.id, bytes);
      if (error != null) {
        _showMessage(error);
      } else {
        _scrollToBottom();
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      final code = error.code.toLowerCase();
      _showMessage(
        code.contains('denied') || code.contains('permission')
            ? 'ไม่ได้รับอนุญาตให้เข้าถึงกล้องหรือรูปภาพ'
            : 'ไม่สามารถเลือกรูปภาพได้: ${error.message ?? error.code}',
      );
    }
  }

  String _statusLabel(MeetupStatus status) {
    switch (status) {
      case MeetupStatus.proposed:
        return 'รอตอบรับ';
      case MeetupStatus.accepted:
        return 'ตกลงแล้ว';
      case MeetupStatus.declined:
        return 'ปฏิเสธ';
      case MeetupStatus.superseded:
        return 'มีข้อเสนอใหม่';
    }
  }

  String _formatDateTime(BuildContext context, DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
