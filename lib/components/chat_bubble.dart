import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

/// Reusable chat message bubble (used in video call chat & chat screen).
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final String? senderName;
  final DateTime? time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMine,
    this.senderName,
    this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.deepBlue : AppColors.iceBlue.withValues(alpha: 0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (senderName != null && !isMine) ...[
              Text(
                senderName!,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mediumBlue,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: isMine ? AppColors.white : AppColors.darkNavy,
                height: 1.3,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 2),
              Text(
                _formatTime(time!),
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 9,
                  color: isMine ? AppColors.iceBlue : AppColors.lightBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}