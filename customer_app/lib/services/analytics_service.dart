import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _client;

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

  void trackWizardStepEntered(int step, String stepName) {
    trackEvent('wizard_step_entered', properties: {'step': step, 'step_name': stepName});
  }

  void trackWizardStepCompleted(int step, String stepName) {
    trackEvent('wizard_step_completed', properties: {'step': step, 'step_name': stepName});
  }

  void trackWizardAbandoned(int step, String stepName) {
    trackEvent('wizard_abandoned', properties: {'step': step, 'step_name': stepName});
  }

  void trackOrderPlaced(String orderId, double amount, int itemCount) {
    trackEvent('order_placed', properties: {'order_id': orderId, 'amount': amount, 'item_count': itemCount});
  }

  void trackProductViewed(String productId, String productName) {
    trackEvent('product_viewed', properties: {'product_id': productId, 'product_name': productName});
  }

  void trackChatStarted() { trackEvent('chat_started'); }

  void trackChatMessageSent(int messageLength) {
    trackEvent('chat_message_sent', properties: {'message_length': messageLength});
  }

  void trackOrderHistoryViewed() { trackEvent('order_history_viewed'); }

  void trackNotificationOpened(String notificationId) {
    trackEvent('notification_opened', properties: {'notification_id': notificationId});
  }

  void trackAppOpened() { trackEvent('app_opened'); }
}
