# PartyPour Analytics & Targeted Notifications

## Overview

Add event tracking to the Flutter customer app, build an analytics dashboard in the admin portal with funnel visualization and user segmentation, and enable targeted push + in-app notifications to user segments from the admin.

## Architecture

- **Event storage**: Supabase `analytics_events` table with JSONB properties
- **Device tokens**: Supabase `device_tokens` table for FCM tokens
- **Flutter tracking**: `AnalyticsService` class, fire-and-forget inserts
- **Admin dashboard**: New `/analytics` route with Funnel, Users, Activity tabs
- **Push notifications**: Supabase Edge Function calling FCM v1 API
- **Query approach**: Near real-time — queries on page load, no Realtime subscriptions

## Prerequisites (User Action Required)

1. Create Firebase project at https://console.firebase.google.com
2. Enable Cloud Messaging
3. Download `google-services.json` → place in `customer_app/android/app/`
4. Download Firebase service account JSON
5. Add as Supabase secret: `supabase secrets set FCM_SERVICE_ACCOUNT_KEY='...'`

Note: Analytics tracking + dashboard can be built and deployed before Firebase setup. Only push notification sending requires FCM credentials.

---

## 1. Database Migrations

### 1.1 analytics_events table

```sql
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

-- Users insert own events
CREATE POLICY "analytics_insert" ON analytics_events
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Admin reads all
CREATE POLICY "analytics_read_admin" ON analytics_events
  FOR SELECT USING (is_admin());
```

### 1.2 device_tokens table

```sql
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

-- Users manage own tokens
CREATE POLICY "device_tokens_insert" ON device_tokens
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "device_tokens_update" ON device_tokens
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "device_tokens_read_admin" ON device_tokens
  FOR SELECT USING (is_admin());
```

---

## 2. Flutter Event Tracking

### 2.1 AnalyticsService

New file: `customer_app/lib/services/analytics_service.dart`

Lightweight service with:
- `trackEvent(String eventName, {Map<String, dynamic>? properties})` — inserts row into `analytics_events`. Fire-and-forget (no await in callers, catch errors silently).
- Singleton pattern, initialized with Supabase client.
- No batching or local queue — direct insert per event. At PartyPour's scale this is fine.

### 2.2 Events to Track

| Event Name | Properties | Integration Point |
|-----------|-----------|-------------------|
| `app_opened` | `{platform, version}` | `main.dart` — app startup |
| `wizard_step_entered` | `{step: 1-6, step_name: "event/types/quantities/brands/review/confirm"}` | Each wizard screen `initState` or equivalent |
| `wizard_step_completed` | `{step: 1-6, step_name}` | Navigation to next step |
| `wizard_abandoned` | `{step: 1-6, step_name}` | Back button / app lifecycle from wizard |
| `order_placed` | `{order_id, amount, item_count}` | `OrderService.createOrder` success |
| `product_viewed` | `{product_id, product_name}` | Product detail screen |
| `chat_started` | `{}` | Chat screen opened |
| `chat_message_sent` | `{message_length}` | User sends message |
| `order_history_viewed` | `{}` | Order history screen |
| `notification_opened` | `{notification_id}` | Notification tapped |

### 2.3 FCM Token Registration

New file: `customer_app/lib/services/push_notification_service.dart`

- Initialize Firebase Messaging on app start
- Request notification permission
- Get FCM token, upsert into `device_tokens` table
- Listen for token refresh, update accordingly
- Handle foreground/background message display using `flutter_local_notifications`

### 2.4 Flutter Dependencies to Add

```yaml
# pubspec.yaml
firebase_core: ^latest
firebase_messaging: ^latest
flutter_local_notifications: ^latest
```

Plus `google-services.json` in `android/app/` and Gradle plugin setup.

---

## 3. Admin Analytics Dashboard

### Route: `/analytics`

Three tabs: **Funnel**, **Users**, **Activity**

### 3.1 Tab: Funnel

Visual conversion funnel showing step-by-step drop-off.

**Data source**: Query `analytics_events` for wizard step events, grouped by step number.

```sql
-- Funnel data for date range
SELECT
  properties->>'step' as step,
  properties->>'step_name' as step_name,
  COUNT(DISTINCT user_id) as users
FROM analytics_events
WHERE event_name = 'wizard_step_entered'
  AND created_at >= [start_date]
GROUP BY step, step_name
ORDER BY step;
```

Also query `order_placed` distinct users for the final conversion step.

**UI**:
- Horizontal funnel bars, each showing user count + percentage of previous step
- Drop-off percentage between each bar highlighted in red
- Date range filter: Last 7 days, 30 days, 90 days, All time
- Summary stat cards at top: Total Users, Funnel Entries, Conversions, Conversion Rate

### 3.2 Tab: Users (Segmented)

Filterable user table with bulk notification action.

**Filters**:
- Segment: All | Converted | Dropped at Step 1 | Dropped at Step 2 | ... | Dropped at Step 6 | Signed Up Only | Active Last 7 Days
- Search: by name or email
- Date range: when user was last active

**"Dropped at Step X"** logic: User's last `wizard_step_entered` event has `step = X` AND user has no `order_placed` event.

**Table columns**: Checkbox | Customer (avatar + name + email) | Segment | Last Wizard Step | Orders | Last Active

**Bulk actions**:
- Select individual users or "Select All in Segment"
- "Send Notification" button → opens modal

**Send Notification Modal**:
- Title field (text input)
- Message field (textarea)
- Preview of how many users will receive it
- "Send" button
- On send: for each selected user, insert into `notifications` table + call Edge Function to send FCM push

### 3.3 Tab: Activity

Live event feed showing recent user actions.

**Data source**: Query last 100 events from `analytics_events` with joined user profile.

**UI**:
- Event list with: avatar + user name, event name (badge), properties (collapsed JSON), timestamp (relative)
- Filter by event type dropdown
- Auto-refresh button (manual, not automatic)

### 3.4 Sidebar

Add Analytics nav item between Customers and Equipment:
```
{ href: '/analytics', label: 'Analytics', icon: BarChart3 }
```

---

## 4. Supabase Edge Function: send-push-notification

### Route: `supabase/functions/send-push-notification/index.ts`

Receives a request with `{ user_ids: string[], title: string, message: string }`.

For each user_id:
1. Look up FCM tokens from `device_tokens` table
2. Send push notification via FCM v1 HTTP API
3. If token is invalid (FCM returns 404/410), delete the stale token

Uses service_role key for Supabase queries (bypasses RLS). FCM service account key from environment secrets.

Called from the admin portal's "Send Notification" action via `supabase.functions.invoke('send-push-notification', { body: ... })`.

---

## 5. Customers Page Update

Update the existing Customers page (`/customers`) and Customer detail page (`/customers/[id]`):

- Add "Last Wizard Step" column to customers table (query from analytics_events)
- Change segment badges: "Converted" (green), "Step 3" (orange with step number), "Signed Up Only" (gray)
- Customer detail page: add "Activity Timeline" section showing their analytics events

---

## 6. Testing

- Playwright CLI: screenshot analytics dashboard tabs (funnel, users, activity)
- Verify event tracking by inserting test events via Supabase SQL, then checking dashboard
- Test notification sending flow: select users → send → verify notification appears in `notifications` table
- FCM push: manual test after Firebase setup (requires real device or emulator with Google Play Services)

## Out of Scope

- Email notifications (Phase 4 — separate spec)
- Automated re-engagement (drip campaigns, scheduled sends)
- A/B testing
- Revenue analytics / financial reporting
- Dashboard charts beyond the funnel (line charts, trends over time)
