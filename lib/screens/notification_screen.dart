import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../styles/colors.dart';
import '../styles/typography.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    // Mark all as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllAsRead();
    });
  }

  Future<void> _markAllAsRead() async {
    if (_marked) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final service = ref.read(notificationServiceProvider);
    await service.markAllAsRead(user.uid);
    setState(() => _marked = true);
    // Invalidate the stream provider to update the count
    ref.invalidate(notificationsStreamProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.titleLarge.copyWith(fontSize: 20)),
        centerTitle: true,
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkNavy),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_marked)
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.deepBlue),
              onPressed: null,
            ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.lightBlue),
                  const SizedBox(height: 16),
                  Text('No notifications', style: AppTypography.bodyLarge),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.iceBlue),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: notif.isRead ? AppColors.iceBlue : AppColors.deepBlue,
                  radius: 6,
                ),
                title: Text(
                  notif.title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif.body, style: AppTypography.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(notif.createdAt),
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 11,
                        color: AppColors.mediumBlue,
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  if (!notif.isRead) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await ref.read(notificationServiceProvider).markAsRead(user.uid, notif.id);
                      ref.invalidate(notificationsStreamProvider);
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.deepBlue)),
        error: (err, stack) => Center(
          child: Text('Failed to load notifications', style: AppTypography.bodyLarge.copyWith(color: AppColors.error)),
        ),
      ),
    );
  }
}