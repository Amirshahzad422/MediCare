import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatMessagesProvider = StreamProvider.family<List<ChatMessageModel>, String>((ref, threadKey) {
  final service = ref.watch(chatServiceProvider);
  return service.watchMessages(threadKey);
});