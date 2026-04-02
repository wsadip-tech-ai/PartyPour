import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationServiceProvider).markAllAsRead();
              ref.invalidate(notificationsProvider);
              ref.read(unreadCountProvider.notifier).refresh();
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text('No notifications yet', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final isUnread = !n.isRead;

                  return Card(
                    color: isUnread ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUnread ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          _getIcon(n.title),
                          color: isUnread ? Colors.white : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.message, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            _timeAgo(n.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () async {
                        if (isUnread) {
                          await ref.read(notificationServiceProvider).markAsRead(n.id);
                          ref.invalidate(notificationsProvider);
                          ref.read(unreadCountProvider.notifier).refresh();
                        }
                        if (n.orderId != null && context.mounted) {
                          context.push('/order/${n.orderId}');
                        }
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  IconData _getIcon(String title) {
    if (title.contains('Confirmed')) return Icons.check_circle;
    if (title.contains('Way') || title.contains('Dispatched')) return Icons.local_shipping;
    if (title.contains('Delivered')) return Icons.celebration;
    if (title.contains('Cancelled')) return Icons.cancel;
    return Icons.notifications;
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
