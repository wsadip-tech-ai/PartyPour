-- 018_analytics_events.sql
-- Analytics event tracking and FCM device tokens

CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  event_name TEXT NOT NULL,
  properties JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_analytics_event_name ON analytics_events(event_name, created_at DESC);
CREATE INDEX idx_analytics_user ON analytics_events(user_id, created_at DESC);
CREATE INDEX idx_analytics_created ON analytics_events(created_at DESC);

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "analytics_insert" ON analytics_events
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "analytics_read_admin" ON analytics_events
  FOR SELECT USING (is_admin());

CREATE TABLE device_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'android',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, token)
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "device_tokens_insert" ON device_tokens
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_tokens_upsert" ON device_tokens
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "device_tokens_read_admin" ON device_tokens
  FOR SELECT USING (is_admin());
