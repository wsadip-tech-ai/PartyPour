-- Clean up duplicate analytics events
-- Keep only the first occurrence per user per event+qualifier

DELETE FROM analytics_events
WHERE id NOT IN (
  SELECT id FROM (SELECT DISTINCT ON (user_id) id FROM analytics_events WHERE event_name = 'app_opened' ORDER BY user_id, created_at ASC) t1
  UNION ALL
  SELECT id FROM (SELECT DISTINCT ON (user_id, properties->>'step') id FROM analytics_events WHERE event_name = 'wizard_step_entered' ORDER BY user_id, properties->>'step', created_at ASC) t2
  UNION ALL
  SELECT id FROM (SELECT DISTINCT ON (user_id, properties->>'step') id FROM analytics_events WHERE event_name = 'wizard_step_completed' ORDER BY user_id, properties->>'step', created_at ASC) t3
  UNION ALL
  SELECT id FROM (SELECT DISTINCT ON (user_id, properties->>'order_id') id FROM analytics_events WHERE event_name = 'order_placed' ORDER BY user_id, properties->>'order_id', created_at ASC) t4
  UNION ALL
  SELECT id FROM (SELECT DISTINCT ON (user_id, properties->>'product_id') id FROM analytics_events WHERE event_name = 'product_viewed' ORDER BY user_id, properties->>'product_id', created_at ASC) t5
  UNION ALL
  SELECT id FROM (SELECT DISTINCT ON (user_id) id FROM analytics_events WHERE event_name = 'chat_started' ORDER BY user_id, created_at ASC) t6
  UNION ALL
  SELECT id FROM (SELECT DISTINCT ON (user_id) id FROM analytics_events WHERE event_name = 'order_history_viewed' ORDER BY user_id, created_at ASC) t7
  UNION ALL
  SELECT id FROM analytics_events WHERE event_name = 'chat_message_sent'
  UNION ALL
  SELECT id FROM analytics_events WHERE event_name = 'notification_opened'
);
