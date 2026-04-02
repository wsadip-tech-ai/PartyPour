import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import 'auth_provider.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(ref.watch(supabaseProvider)),
);

final unreadCountProvider = StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) => UnreadCountNotifier(ref.watch(notificationServiceProvider)),
);

class UnreadCountNotifier extends StateNotifier<int> {
  final NotificationService _service;
  Timer? _pollTimer;

  UnreadCountNotifier(this._service) : super(0) {
    _fetch();
    // Poll every 30 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  Future<void> _fetch() async {
    state = await _service.getUnreadCount();
  }

  void refresh() => _fetch();

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationServiceProvider).getNotifications();
});
