import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/chat_bubble.dart';
import '../components/empty_state.dart';
import '../components/loader.dart';
import '../layouts/responsive_layout.dart';
import '../providers/chat_provider.dart';
import '../services/chat_service.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final String _threadKey;
  String _doctorName = 'Doctor';
  String _doctorPhoto = '';

  @override
  void initState() {
    super.initState();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _doctorName = args['doctorName'] ?? 'Doctor';
      _doctorPhoto = args['doctorPhoto'] ?? '';
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _threadKey = ChatService.threadKey(uid, _doctorName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(chatServiceProvider).sendMessage(_threadKey, _controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(_threadKey));

    return ResponsiveLayout(
      currentRoute: '/chat',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.iceBlue.withValues(alpha: 0.3),
              border: const Border(bottom: BorderSide(color: AppColors.iceBlue)),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: _doctorPhoto.isNotEmpty && _doctorPhoto.startsWith('http')
                      ? Image.network(
                          _doctorPhoto,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 42,
                            height: 42,
                            color: AppColors.deepBlue,
                            child: const Icon(Icons.person, color: AppColors.white, size: 22),
                          ),
                        )
                      : Container(
                          width: 42,
                          height: 42,
                          color: AppColors.deepBlue,
                          child: const Icon(Icons.person, color: AppColors.white, size: 22),
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _doctorName,
                      style: AppTypography.titleLarge.copyWith(fontSize: 16),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Online',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'Start the conversation',
                    subtitle: 'Send a message to the doctor about your symptoms.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine =
                        msg.senderId == (FirebaseAuth.instance.currentUser?.uid ?? '');
                    return ChatBubble(
                      text: msg.text,
                      isMine: isMine,
                      senderName: isMine ? null : msg.senderName,
                      time: msg.at,
                    );
                  },
                );
              },
              loading: () => const LoadingIndicator(),
              error: (err, stack) => const EmptyState(
                icon: Icons.cloud_off,
                title: 'Chat unavailable',
                subtitle: 'Check your connection and try again.',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.iceBlue)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTypography.bodyMedium,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.lightBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.lightBlue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.deepBlue,
                  child: IconButton(
                    tooltip: 'Send',
                    onPressed: _send,
                    icon: const Icon(Icons.send, color: AppColors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}