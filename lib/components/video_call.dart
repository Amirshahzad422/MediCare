import 'package:flutter/material.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

/// Shared in-call control bar (mute, camera toggle, chat, end call).
class VideoCallControls extends StatelessWidget {
  final bool isMuted;
  final bool isCameraOff;
  final bool chatOpen;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleChat;
  final VoidCallback onEndCall;

  const VideoCallControls({
    super.key,
    required this.isMuted,
    required this.isCameraOff,
    required this.chatOpen,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onToggleChat,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkNavy.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            color: isMuted ? AppColors.error : AppColors.white,
            tooltip: isMuted ? 'Unmute' : 'Mute',
            onPressed: onToggleMute,
          ),
          _ControlButton(
            icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
            color: isCameraOff ? AppColors.error : AppColors.white,
            tooltip: isCameraOff ? 'Turn camera on' : 'Turn camera off',
            onPressed: onToggleCamera,
          ),
          _ControlButton(
            icon: Icons.chat,
            color: chatOpen ? AppColors.iceBlue : AppColors.white,
            tooltip: 'In-call chat',
            onPressed: onToggleChat,
          ),
          CircleAvatar(
            backgroundColor: AppColors.error,
            radius: 24,
            child: IconButton(
              tooltip: 'End call',
              icon: const Icon(Icons.call_end, color: AppColors.white),
              onPressed: onEndCall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
    );
  }
}

/// Self-view placeholder shown in a video call before camera is ready.
class SelfViewPlaceholder extends StatelessWidget {
  final String doctorPhoto;
  final String? errorMessage;

  const SelfViewPlaceholder({
    super.key,
    required this.doctorPhoto,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.deepBlue,
      child: errorMessage != null
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            )
          : doctorPhoto.isNotEmpty && doctorPhoto.startsWith('http')
              ? Image.network(
                  doctorPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.person, color: AppColors.white, size: 30),
                  ),
                )
              : const Center(
                  child: Icon(Icons.person, color: AppColors.white, size: 30),
                ),
    );
  }
}