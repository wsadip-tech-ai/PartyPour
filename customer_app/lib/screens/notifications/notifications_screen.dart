import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFFA8A29E);
const _mutedDark = Color(0xFF78716C);
const _border = Color(0xFF44403C);

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight),
        ),
        iconTheme: const IconThemeData(color: _textLight),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.read(unreadCountProvider.notifier).refresh();
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? _buildEmpty()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  return _NotificationCard(
                    notification: n,
                    onTap: () async {
                      ref.read(analyticsProvider).trackNotificationOpened(n.id);
                      if (!n.isRead) {
                        await ref.read(notificationServiceProvider).markAsRead(n.id);
                        ref.invalidate(notificationsProvider);
                        ref.read(unreadCountProvider.notifier).refresh();
                      }
                      if (n.orderId != null && context.mounted) {
                        context.push('/order/${n.orderId}');
                      }
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: _muted)),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 36, color: _mutedDark),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _muted),
          ),
          const SizedBox(height: 6),
          const Text(
            'Order updates and alerts will appear here',
            style: TextStyle(fontSize: 13, color: _mutedDark),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final isUnread = !n.isRead;
    final iconData = _getIcon(n.title);
    final iconColor = _getIconColor(n.title);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFF1F1C18) : _surfaceDark,
          border: Border.all(
            color: isUnread ? _gold.withValues(alpha: 0.35) : _border,
            width: isUnread ? 1.0 : 0.8,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                        color: _textLight,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: const TextStyle(fontSize: 12, color: _muted, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(n.createdAt),
                      style: const TextStyle(fontSize: 11, color: _mutedDark),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: _goldLight, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String title) {
    if (title.contains('Confirmed')) return Icons.check_circle_rounded;
    if (title.contains('Way') || title.contains('Dispatched')) return Icons.local_shipping_rounded;
    if (title.contains('Delivered')) return Icons.celebration_rounded;
    if (title.contains('Cancelled')) return Icons.cancel_rounded;
    return Icons.notifications_rounded;
  }

  Color _getIconColor(String title) {
    if (title.contains('Confirmed')) return const Color(0xFF4ade80);
    if (title.contains('Way') || title.contains('Dispatched')) return const Color(0xFF60a5fa);
    if (title.contains('Delivered')) return const Color(0xFFc084fc);
    if (title.contains('Cancelled')) return const Color(0xFFEF4444);
    return _goldLight;
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
