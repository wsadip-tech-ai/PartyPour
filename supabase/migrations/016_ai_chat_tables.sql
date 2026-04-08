-- 016_ai_chat_tables.sql
-- Tables for AI chatbot: company knowledge base + chat history

-- ============================================
-- Company docs — knowledge base for AI chatbot
-- ============================================
CREATE TABLE company_docs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'general',
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_company_docs_updated_at
  BEFORE UPDATE ON company_docs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE company_docs ENABLE ROW LEVEL SECURITY;

-- Everyone can read active docs (edge function needs this)
CREATE POLICY "company_docs_read" ON company_docs
  FOR SELECT USING (is_active = true OR is_admin());

CREATE POLICY "company_docs_admin_insert" ON company_docs
  FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "company_docs_admin_update" ON company_docs
  FOR UPDATE USING (is_admin());

CREATE POLICY "company_docs_admin_delete" ON company_docs
  FOR DELETE USING (is_admin());

-- ============================================
-- Chat messages — per-user conversation history
-- ============================================
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can only see their own messages
CREATE POLICY "chat_messages_own_read" ON chat_messages
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "chat_messages_own_insert" ON chat_messages
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admin can read all
CREATE POLICY "chat_messages_admin_read" ON chat_messages
  FOR SELECT USING (is_admin());

-- Index for fast user message retrieval
CREATE INDEX idx_chat_messages_user ON chat_messages(user_id, created_at DESC);

-- ============================================
-- Seed some initial company docs
-- ============================================
INSERT INTO company_docs (title, content, category) VALUES
  ('About PartyPour', 'PartyPour is Nepal''s premier event beverage service. We provide genuine, competitively priced beverages for weddings, birthdays, corporate events, house parties, and anniversaries. Our tagline: Right price. Genuine. Returnable.', 'general'),
  ('Delivery Policy', 'We deliver within Kathmandu Valley. Orders must be placed at least 24 hours before the event. Delivery is free for orders above NPR 20,000. For smaller orders, a delivery fee of NPR 500 applies.', 'delivery'),
  ('Return Policy', 'Unopened bottles and cases can be returned within 3 days of delivery for a full refund. Opened or damaged items cannot be returned. Contact us to arrange pickup.', 'returns'),
  ('Payment Options', 'We accept cash on delivery, bank transfer, and eSewa/Khalti digital payments. Full payment is required before or on delivery. Credit terms available for corporate accounts.', 'payment'),
  ('Product Range', 'We carry 60+ brands across whiskey, vodka, gin, rum, brandy, beer, wine, shots/specials, energy drinks, sodas, ice cream, and more. Both domestic and imported brands available. If you can''t find a brand, use our "Request a Brand" feature.', 'products'),
  ('Pricing & Offers', 'Our prices are competitive and transparent. Case pricing available for bulk orders with significant savings. Seasonal promotions run during wedding season and festivals. Check the app for current offers.', 'pricing'),
  ('Operating Hours', 'Our service operates from 9 AM to 9 PM, 7 days a week. Orders placed after 6 PM may be delivered the next day. For urgent same-day delivery, contact us directly.', 'hours');
