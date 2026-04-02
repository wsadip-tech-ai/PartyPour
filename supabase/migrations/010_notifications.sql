-- 010_notifications.sql
-- Order notifications for customers

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY "notifications_read_own" ON notifications
  FOR SELECT USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE USING (user_id = auth.uid());

-- Admins can insert notifications for any user
CREATE POLICY "notifications_admin_insert" ON notifications
  FOR INSERT WITH CHECK (is_admin());

-- Admins can read all notifications
CREATE POLICY "notifications_admin_read" ON notifications
  FOR SELECT USING (is_admin());

-- Auto-create notification when order status changes
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
DECLARE
  notification_title TEXT;
  notification_message TEXT;
BEGIN
  -- Only fire when status actually changes
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  notification_title := CASE NEW.status
    WHEN 'confirmed' THEN 'Order Confirmed!'
    WHEN 'dispatched' THEN 'Order On the Way!'
    WHEN 'delivered' THEN 'Order Delivered!'
    WHEN 'cancelled' THEN 'Order Cancelled'
    ELSE 'Order Updated'
  END;

  notification_message := CASE NEW.status
    WHEN 'confirmed' THEN 'Your order #' || LEFT(NEW.id::text, 8) || ' has been confirmed. We are preparing your beverages.'
    WHEN 'dispatched' THEN 'Your order #' || LEFT(NEW.id::text, 8) || ' is on the way! Please be ready at the delivery address.'
    WHEN 'delivered' THEN 'Your order #' || LEFT(NEW.id::text, 8) || ' has been delivered. Enjoy your event!'
    WHEN 'cancelled' THEN 'Your order #' || LEFT(NEW.id::text, 8) || ' has been cancelled. Please contact us for any questions.'
    ELSE 'Your order #' || LEFT(NEW.id::text, 8) || ' status has been updated to ' || NEW.status || '.'
  END;

  INSERT INTO public.notifications (user_id, order_id, title, message)
  VALUES (NEW.user_id, NEW.id, notification_title, notification_message);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_order_status_notification
  AFTER UPDATE OF status ON orders
  FOR EACH ROW EXECUTE FUNCTION notify_order_status_change();
