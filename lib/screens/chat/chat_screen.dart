import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../services/chat_service.dart';
import '../../models/chat_message_model.dart';
import '../../widgets/chat_bubble.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final room = context.read<RoomProvider>().currentRoom;
    if (room == null || auth.user == null) return;

    _controller.clear();
    await _chatService.sendMessage(
      roomId: room.id,
      senderUid: auth.user!.uid,
      senderName: auth.user!.displayName,
      senderPhotoUrl: auth.user!.photoUrl,
      content: text,
    );

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomProvider>().currentRoom;
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    if (room == null) {
      return const Center(child: Text('Not in a room'));
    }

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<ChatMessageModel>>(
            stream: _chatService.watchMessages(room.id),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snap.data!;
              if (messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: AppColors.onSurface.withAlpha(80),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No messages yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start the conversation',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final isMe = msg.senderUid == uid;
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(msg.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(
                          isMe ? 20 * (1 - value) : -20 * (1 - value),
                          0,
                        ),
                        child: child,
                      ),
                    ),
                    child: ChatBubble(message: msg, isMe: isMe),
                  );
                },
              );
            },
          ),
        ),
        _MessageInput(
          controller: _controller,
          onSend: _send,
        ),
      ],
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Message...',
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 18, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
