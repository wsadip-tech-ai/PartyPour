import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _client;

  /// Tracks which events have already been fired this session to prevent duplicates.
  /// Key format: "event_name" or "event_name:qualifier" for parameterized events.
  final Set<String> _firedThisSession = {};

  AnalyticsService(this._client);

  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _client.from('analytics_events').insert({
      'user_id': userId,
      'event_name': eventName,
      'properties': properties ?? {},
    }).then((_) {}).catchError((_) {});
  }

  /// Fire an event only once per session. Returns true if fired, false if already sent.
  bool _trackOnce(String key, String eventName, {Map<String, dynamic>? properties}) {
    if (_firedThisSession.contains(key)) return false;
    _firedThisSession.add(key);
    trackEvent(eventName, properties: properties);
    return true;
  }

  void trackAppOpened() {
    _trackOnce('app_opened', 'app_opened');
  }

  void trackWizardStepEntered(int step, String stepName) {
    _trackOnce('wizard_step_entered:$step', 'wizard_step_entered',
        properties: {'step': step, 'step_name': stepName});
  }

  void trackWizardStepCompleted(int step, String stepName) {
    _trackOnce('wizard_step_completed:$step', 'wizard_step_completed',
        properties: {'step': step, 'step_name': stepName});
  }

  void trackOrderPlaced(String orderId, double amount, int itemCount) {
    _trackOnce('order_placed:$orderId', 'order_placed',
        properties: {'order_id': orderId, 'amount': amount, 'item_count': itemCount});
  }

  void trackProductViewed(String productId, String productName) {
    _trackOnce('product_viewed:$productId', 'product_viewed',
        properties: {'product_id': productId, 'product_name': productName});
  }

  void trackChatStarted() {
    _trackOnce('chat_started', 'chat_started');
  }

  void trackChatMessageSent(int messageLength) {
    // Chat messages are intentionally NOT deduplicated — each message is a unique action
    trackEvent('chat_message_sent', properties: {'message_length': messageLength});
  }

  void trackOrderHistoryViewed() {
    _trackOnce('order_history_viewed', 'order_history_viewed');
  }

  void trackNotificationOpened(String notificationId) {
    // Not deduplicated — user may open same notification multiple times intentionally
    trackEvent('notification_opened', properties: {'notification_id': notificationId});
  }
}
