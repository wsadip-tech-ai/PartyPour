import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import 'auth_provider.dart';
import 'order_provider.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(supabaseProvider)),
);

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) => UnreadCountNotifier(ref, ref.watch(notificationServiceProvider), ref.watch(supabaseProvider)),
);

class UnreadCountNotifier extends StateNotifier<int> {
  final Ref _ref;
  final NotificationService _service;
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  UnreadCountNotifier(this._ref, this._service, this._client) : super(0) {
    _fetch();
    _subscribeRealtime();
  }

  Future<void> _fetch() async {
    state = await _service.getUnreadCount();
  }

  void _subscribeRealtime() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _channel = _client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (payload) {
            // New notification inserted — refresh count + order list + notifications screen
            _fetch();
            _ref.invalidate(orderHistoryProvider);
            _ref.invalidate(notificationsProvider);
          },
        )
        .subscribe();
  }

  void refresh() => _fetch();

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>((ref) {
  // Re-fetch every time screen is opened (autoDispose ensures this)
  return ref.watch(notificationServiceProvider).getNotifications();
});
