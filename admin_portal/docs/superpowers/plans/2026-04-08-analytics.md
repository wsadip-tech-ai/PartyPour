# Analytics & Targeted Notifications Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add event tracking to the Flutter customer app, build an analytics dashboard in the admin portal with funnel/segmentation/activity views, and enable targeted push + in-app notifications from admin to user segments.

**Architecture:** New Supabase tables (`analytics_events`, `device_tokens`) store tracking data and FCM tokens. Flutter `AnalyticsService` fires events on user actions. Admin dashboard queries events for funnel visualization and user segmentation. A Supabase Edge Function handles FCM push delivery. All queries are near real-time (on page load).

**Tech Stack:** Flutter/Dart (Riverpod, GoRouter, Supabase), Next.js 16 (App Router, shadcn/ui, Tailwind), Supabase (PostgreSQL, Edge Functions/Deno, RLS), Firebase Cloud Messaging

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `supabase/migrations/018_analytics_events.sql` | analytics_events + device_tokens tables |
| Create | `customer_app/lib/services/analytics_service.dart` | Event tracking service |
| Create | `customer_app/lib/services/push_notification_service.dart` | FCM token management + push handling |
| Modify | `customer_app/lib/main.dart` | Initialize analytics + push services |
| Modify | `customer_app/lib/screens/wizard/wizard_event_screen.dart` | Track wizard step 1 |
| Modify | `customer_app/lib/screens/wizard/wizard_types_screen.dart` | Track wizard step 2 |
| Modify | `customer_app/lib/screens/wizard/wizard_quantities_screen.dart` | Track wizard step 3 |
| Modify | `customer_app/lib/screens/wizard/wizard_brands_screen.dart` | Track wizard step 4 |
| Modify | `customer_app/lib/screens/wizard/wizard_review_screen.dart` | Track wizard step 5 |
| Modify | `customer_app/lib/screens/wizard/wizard_confirm_screen.dart` | Track wizard step 6 + order_placed |
| Modify | `customer_app/lib/screens/chat/chat_screen.dart` | Track chat events |
| Modify | `customer_app/lib/screens/orders/order_history_screen.dart` | Track order history viewed |
| Modify | `customer_app/lib/screens/notifications/notifications_screen.dart` | Track notification opened |
| Modify | `customer_app/lib/screens/catalog/product_detail_screen.dart` | Track product viewed |
| Create | `supabase/functions/send-push-notification/index.ts` | FCM push delivery edge function |
| Create | `admin_portal/src/app/analytics/page.tsx` | Analytics dashboard — funnel tab |
| Create | `admin_portal/src/app/analytics/users/page.tsx` | Analytics — segmented users tab |
| Create | `admin_portal/src/app/analytics/activity/page.tsx` | Analytics — activity feed tab |
| Create | `admin_portal/src/app/analytics/layout.tsx` | Analytics tabs layout |
| Create | `admin_portal/src/components/funnel-chart.tsx` | Funnel visualization component |
| Create | `admin_portal/src/components/send-notification-modal.tsx` | Bulk notification modal |
| Modify | `admin_portal/src/components/sidebar.tsx` | Add Analytics nav item |
| Modify | `admin_portal/src/app/customers/page.tsx` | Add wizard drop-off column |
| Modify | `customer_app/pubspec.yaml` | Add Firebase dependencies |
| Modify | `customer_app/android/app/build.gradle.kts` | Add Google Services plugin |
| Modify | `customer_app/android/build.gradle.kts` | Add Google Services classpath |

---

### Task 1: Database migration — analytics_events + device_tokens

**Files:**
- Create: `supabase/migrations/018_analytics_events.sql`

- [ ] **Step 1: Create migration file**

```sql
-- 018_analytics_events.sql
-- Analytics event tracking and FCM device tokens

-- Analytics events table
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

-- Device tokens table for FCM
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
```

- [ ] **Step 2: Apply migration**

```bash
cd root_raksichaiyo && supabase db push
```

If `supabase` CLI is not set up for remote, apply via Supabase SQL Editor instead — copy-paste the SQL above and run it.

- [ ] **Step 3: Verify tables exist**

```bash
curl -s "https://wckuawushetknwpyswqm.supabase.co/rest/v1/analytics_events?select=id&limit=1" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY"
```

Expected: `[]` (empty array, not an error)

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/018_analytics_events.sql
git commit -m "feat: add analytics_events and device_tokens tables"
```

---

### Task 2: Flutter AnalyticsService

**Files:**
- Create: `customer_app/lib/services/analytics_service.dart`

- [ ] **Step 1: Create analytics service**

```dart
// lib/services/analytics_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _client;

  AnalyticsService(this._client);

  /// Fire-and-forget event tracking. Never throws, never blocks.
  void trackEvent(String eventName, {Map<String, dynamic>? properties}) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Fire and forget — don't await, catch silently
    _client.from('analytics_events').insert({
      'user_id': userId,
      'event_name': eventName,
      'properties': properties ?? {},
    }).then((_) {}).catchError((_) {});
  }

  void trackWizardStepEntered(int step, String stepName) {
    trackEvent('wizard_step_entered', properties: {
      'step': step,
      'step_name': stepName,
    });
  }

  void trackWizardStepCompleted(int step, String stepName) {
    trackEvent('wizard_step_completed', properties: {
      'step': step,
      'step_name': stepName,
    });
  }

  void trackWizardAbandoned(int step, String stepName) {
    trackEvent('wizard_abandoned', properties: {
      'step': step,
      'step_name': stepName,
    });
  }

  void trackOrderPlaced(String orderId, double amount, int itemCount) {
    trackEvent('order_placed', properties: {
      'order_id': orderId,
      'amount': amount,
      'item_count': itemCount,
    });
  }

  void trackProductViewed(String productId, String productName) {
    trackEvent('product_viewed', properties: {
      'product_id': productId,
      'product_name': productName,
    });
  }

  void trackChatStarted() {
    trackEvent('chat_started');
  }

  void trackChatMessageSent(int messageLength) {
    trackEvent('chat_message_sent', properties: {
      'message_length': messageLength,
    });
  }

  void trackOrderHistoryViewed() {
    trackEvent('order_history_viewed');
  }

  void trackNotificationOpened(String notificationId) {
    trackEvent('notification_opened', properties: {
      'notification_id': notificationId,
    });
  }

  void trackAppOpened() {
    trackEvent('app_opened');
  }
}
```

- [ ] **Step 2: Add provider in auth_provider.dart**

In `customer_app/lib/providers/auth_provider.dart`, add the analytics provider after the existing providers:

```dart
import '../services/analytics_service.dart';

final analyticsProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(ref.watch(supabaseProvider)),
);
```

- [ ] **Step 3: Commit**

```bash
cd customer_app
git add lib/services/analytics_service.dart lib/providers/auth_provider.dart
git commit -m "feat: add AnalyticsService with fire-and-forget event tracking"
```

---

### Task 3: Instrument Flutter wizard screens with analytics

**Files:**
- Modify: `customer_app/lib/screens/wizard/wizard_event_screen.dart`
- Modify: `customer_app/lib/screens/wizard/wizard_types_screen.dart`
- Modify: `customer_app/lib/screens/wizard/wizard_quantities_screen.dart`
- Modify: `customer_app/lib/screens/wizard/wizard_brands_screen.dart`
- Modify: `customer_app/lib/screens/wizard/wizard_review_screen.dart`
- Modify: `customer_app/lib/screens/wizard/wizard_confirm_screen.dart`

For each wizard screen, the pattern is the same:
1. Import analytics provider
2. Track `wizard_step_entered` when the screen renders
3. Track `wizard_step_completed` when navigating to the next step

- [ ] **Step 1: Instrument wizard_event_screen.dart (Step 1)**

Add import at top:
```dart
import '../../providers/auth_provider.dart';
```

In the `build()` method, after `final wizard = ref.watch(wizardProvider);`, add a one-time tracker. Since `WizardEventScreen` is a `ConsumerWidget`, use a ref.listen or track in the build with a flag. Simplest: add tracking call right after build starts — the fire-and-forget nature means duplicate calls are harmless, but to avoid spam, track only in the "Next" button's onPressed, BEFORE navigation:

Find the navigation to `/wizard/types` (the "Next" button's onPressed) and add before `context.push('/wizard/types')`:
```dart
ref.read(analyticsProvider).trackWizardStepCompleted(1, 'event');
```

And at the very start of `build()`, add:
```dart
ref.read(analyticsProvider).trackWizardStepEntered(1, 'event');
```

Note: Since `build()` can fire multiple times, and our tracking is fire-and-forget, occasional duplicate events are acceptable at this scale. The funnel query uses `COUNT(DISTINCT user_id)` which deduplicates.

- [ ] **Step 2: Instrument wizard_types_screen.dart (Step 2)**

Add import: `import '../../providers/auth_provider.dart';`

In `build()`, add near top: `ref.read(analyticsProvider).trackWizardStepEntered(2, 'types');`

Before navigation to `/wizard/quantities` in the "Next" button: `ref.read(analyticsProvider).trackWizardStepCompleted(2, 'types');`

- [ ] **Step 3: Instrument wizard_quantities_screen.dart (Step 3)**

Add import: `import '../../providers/auth_provider.dart';`

In the `initState()` post-frame callback (around line 55), add: `ref.read(analyticsProvider).trackWizardStepEntered(3, 'quantities');`

Before navigation to `/wizard/brands`: `ref.read(analyticsProvider).trackWizardStepCompleted(3, 'quantities');`

- [ ] **Step 4: Instrument wizard_brands_screen.dart (Step 4)**

Add import: `import '../../providers/auth_provider.dart';`

In `build()`, add near top: `ref.read(analyticsProvider).trackWizardStepEntered(4, 'brands');`

Before navigation to `/wizard/review`: `ref.read(analyticsProvider).trackWizardStepCompleted(4, 'brands');`

- [ ] **Step 5: Instrument wizard_review_screen.dart (Step 5)**

Add import: `import '../../providers/auth_provider.dart';`

In `initState()`, add: `ref.read(analyticsProvider).trackWizardStepEntered(5, 'review');`

Before navigation to `/wizard/confirm` (in `_goToConfirm()`): `ref.read(analyticsProvider).trackWizardStepCompleted(5, 'review');`

- [ ] **Step 6: Instrument wizard_confirm_screen.dart (Step 6)**

Add import: `import '../../providers/auth_provider.dart';`

In `build()`, add near top: `ref.read(analyticsProvider).trackWizardStepEntered(6, 'confirm');`

In `_placeOrder()`, after successful order creation (after `order` variable is set), add:
```dart
ref.read(analyticsProvider).trackWizardStepCompleted(6, 'confirm');
ref.read(analyticsProvider).trackOrderPlaced(order.id, wizard.grandTotal, wizard.allSelections.length);
```

- [ ] **Step 7: Commit**

```bash
cd customer_app
git add lib/screens/wizard/
git commit -m "feat: instrument all 6 wizard screens with analytics tracking"
```

---

### Task 4: Instrument remaining Flutter screens

**Files:**
- Modify: `customer_app/lib/main.dart`
- Modify: `customer_app/lib/screens/chat/chat_screen.dart`
- Modify: `customer_app/lib/screens/orders/order_history_screen.dart`
- Modify: `customer_app/lib/screens/notifications/notifications_screen.dart`
- Modify: `customer_app/lib/screens/catalog/product_detail_screen.dart`

- [ ] **Step 1: Track app_opened in main.dart**

In `main.dart`, after Supabase initialization succeeds (after line 15), and after ProviderScope is created, we need to track app_opened. Since main doesn't have ref access directly, add tracking in the `PartyPourApp` widget's build. In the `build()` method of `PartyPourApp` (it's a ConsumerWidget), add near the top:

```dart
ref.read(analyticsProvider).trackAppOpened();
```

Import: `import 'providers/auth_provider.dart';`

Note: This fires on every hot reload during dev — acceptable since we deduplicate by user_id in queries.

- [ ] **Step 2: Track chat events in chat_screen.dart**

Add import: `import '../../providers/auth_provider.dart';`

In `initState()` (line 40), add: `ref.read(analyticsProvider).trackChatStarted();`

In `_sendMessage()` (line 81), before the API call, add:
```dart
ref.read(analyticsProvider).trackChatMessageSent(message.length);
```

Where `message` is the user's input text.

- [ ] **Step 3: Track order_history_viewed**

In `order_history_screen.dart`, add import: `import '../../providers/auth_provider.dart';`

Since this is a `ConsumerWidget`, in `build()` add near top: `ref.read(analyticsProvider).trackOrderHistoryViewed();`

- [ ] **Step 4: Track notification_opened**

In `notifications_screen.dart`, add import: `import '../../providers/auth_provider.dart';`

In the notification tap handler (around line 55-66), before marking as read or navigating, add:
```dart
ref.read(analyticsProvider).trackNotificationOpened(n.id);
```

- [ ] **Step 5: Track product_viewed**

In `product_detail_screen.dart`, add import: `import '../../providers/auth_provider.dart';`

In `initState()` or the build method, after the product data loads, add:
```dart
ref.read(analyticsProvider).trackProductViewed(widget.productId, product.name);
```

If product name isn't available in initState, track in the `.when(data: ...)` callback where the product data is available.

- [ ] **Step 6: Commit**

```bash
cd customer_app
git add lib/main.dart lib/screens/chat/ lib/screens/orders/ lib/screens/notifications/ lib/screens/catalog/
git commit -m "feat: instrument app_opened, chat, orders, notifications, product views"
```

---

### Task 5: Admin analytics layout + funnel tab

**Files:**
- Create: `admin_portal/src/app/analytics/layout.tsx`
- Create: `admin_portal/src/app/analytics/page.tsx`
- Create: `admin_portal/src/components/funnel-chart.tsx`

- [ ] **Step 1: Create analytics tabs layout**

```tsx
// admin_portal/src/app/analytics/layout.tsx
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'

const tabs = [
  { href: '/analytics', label: 'Funnel' },
  { href: '/analytics/users', label: 'Users' },
  { href: '/analytics/activity', label: 'Activity' },
]

export default function AnalyticsLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()

  return (
    <div>
      <h1 className="text-3xl font-bold mb-2">Analytics</h1>
      <p className="text-muted-foreground mb-6">Track user behavior, conversion funnels, and engagement</p>
      <div className="flex gap-1 border-b mb-8">
        {tabs.map((tab) => {
          const isActive = tab.href === '/analytics' ? pathname === '/analytics' : pathname.startsWith(tab.href)
          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={cn(
                'px-4 py-2 text-sm font-medium border-b-2 -mb-px transition-colors',
                isActive
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground'
              )}
            >
              {tab.label}
            </Link>
          )
        })}
      </div>
      {children}
    </div>
  )
}
```

- [ ] **Step 2: Create funnel chart component**

```tsx
// admin_portal/src/components/funnel-chart.tsx

interface FunnelStep {
  label: string
  count: number
}

export function FunnelChart({ steps }: { steps: FunnelStep[] }) {
  const maxCount = steps[0]?.count || 1

  return (
    <div className="space-y-3">
      {steps.map((step, i) => {
        const prevCount = i > 0 ? steps[i - 1].count : step.count
        const dropOff = prevCount > 0 ? ((prevCount - step.count) / prevCount * 100).toFixed(1) : '0'
        const widthPct = Math.max((step.count / maxCount) * 100, 8)
        const isFirst = i === 0

        return (
          <div key={step.label}>
            {!isFirst && prevCount > step.count && (
              <div className="flex items-center gap-2 ml-4 mb-1">
                <span className="text-xs text-red-500 font-medium">↓ {dropOff}% drop-off ({prevCount - step.count} users)</span>
              </div>
            )}
            <div className="flex items-center gap-3">
              <span className="text-sm font-medium w-32 text-right shrink-0">{step.label}</span>
              <div className="flex-1">
                <div
                  className="h-10 rounded-md flex items-center px-3 text-sm font-bold text-white transition-all"
                  style={{
                    width: `${widthPct}%`,
                    backgroundColor: `hsl(${150 - (i * 20)}, 70%, ${45 + (i * 5)}%)`,
                  }}
                >
                  {step.count}
                </div>
              </div>
              <span className="text-xs text-muted-foreground w-16 shrink-0">
                {i > 0 ? `${((step.count / (steps[0]?.count || 1)) * 100).toFixed(0)}%` : '100%'}
              </span>
            </div>
          </div>
        )
      })}
    </div>
  )
}
```

- [ ] **Step 3: Create funnel page**

```tsx
// admin_portal/src/app/analytics/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatCard } from '@/components/stat-card'
import { FunnelChart } from '@/components/funnel-chart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Users, UserCheck, TrendingDown, BarChart3 } from 'lucide-react'

const dateRanges: Record<string, number> = {
  '7d': 7,
  '30d': 30,
  '90d': 90,
  'all': 0,
}

export default function AnalyticsFunnelPage() {
  const supabase = createClient()
  const [range, setRange] = useState('30d')
  const [funnelData, setFunnelData] = useState<{ label: string; count: number }[]>([])
  const [totalUsers, setTotalUsers] = useState(0)
  const [conversions, setConversions] = useState(0)

  const fetchFunnel = useCallback(async () => {
    const days = dateRanges[range]
    const since = days > 0
      ? new Date(Date.now() - days * 86400000).toISOString()
      : '2020-01-01T00:00:00Z'

    // Get wizard step entries (distinct users per step)
    const { data: stepData } = await supabase
      .from('analytics_events')
      .select('user_id, properties')
      .eq('event_name', 'wizard_step_entered')
      .gte('created_at', since)

    // Get order_placed distinct users
    const { data: orderData } = await supabase
      .from('analytics_events')
      .select('user_id')
      .eq('event_name', 'order_placed')
      .gte('created_at', since)

    // Get total unique users who opened app
    const { data: appData } = await supabase
      .from('analytics_events')
      .select('user_id')
      .eq('event_name', 'app_opened')
      .gte('created_at', since)

    const appUsers = new Set((appData ?? []).map((e: any) => e.user_id))
    const stepNames = ['event', 'types', 'quantities', 'brands', 'review', 'confirm']
    const stepCounts = stepNames.map((name, i) => {
      const users = new Set(
        (stepData ?? [])
          .filter((e: any) => e.properties?.step === i + 1)
          .map((e: any) => e.user_id)
      )
      return { label: `Step ${i + 1}: ${name.charAt(0).toUpperCase() + name.slice(1)}`, count: users.size }
    })

    const orderUsers = new Set((orderData ?? []).map((e: any) => e.user_id))

    const funnel = [
      { label: 'App Opened', count: appUsers.size },
      ...stepCounts,
      { label: 'Order Placed', count: orderUsers.size },
    ]

    setFunnelData(funnel)
    setTotalUsers(appUsers.size)
    setConversions(orderUsers.size)
  }, [range])

  useEffect(() => { fetchFunnel() }, [fetchFunnel])

  const conversionRate = totalUsers > 0 ? ((conversions / totalUsers) * 100).toFixed(1) : '0'
  const funnelEntries = funnelData[1]?.count ?? 0

  return (
    <div className="space-y-6">
      {/* Date range filter */}
      <div className="flex justify-end">
        <Select value={range} onValueChange={(v) => setRange(v ?? '30d')}>
          <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="7d">Last 7 days</SelectItem>
            <SelectItem value="30d">Last 30 days</SelectItem>
            <SelectItem value="90d">Last 90 days</SelectItem>
            <SelectItem value="all">All time</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard title="Total Users" value={totalUsers} icon={Users} />
        <StatCard title="Funnel Entries" value={funnelEntries} icon={BarChart3} description="Started wizard" />
        <StatCard title="Conversions" value={conversions} icon={UserCheck} description="Placed an order" />
        <StatCard title="Conversion Rate" value={`${conversionRate}%`} icon={TrendingDown} description="App open → order" />
      </div>

      {/* Funnel chart */}
      <Card>
        <CardHeader><CardTitle>Conversion Funnel</CardTitle></CardHeader>
        <CardContent>
          {funnelData.length > 0 ? (
            <FunnelChart steps={funnelData} />
          ) : (
            <p className="text-muted-foreground text-center py-8">No analytics data yet. Events will appear once users interact with the app.</p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 4: Commit**

```bash
cd admin_portal
git add src/app/analytics/layout.tsx src/app/analytics/page.tsx src/components/funnel-chart.tsx
git commit -m "feat: add analytics funnel dashboard with conversion visualization"
```

---

### Task 6: Admin analytics — segmented users tab + notification modal

**Files:**
- Create: `admin_portal/src/app/analytics/users/page.tsx`
- Create: `admin_portal/src/components/send-notification-modal.tsx`

- [ ] **Step 1: Create send notification modal**

```tsx
// admin_portal/src/components/send-notification-modal.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'

interface SendNotificationModalProps {
  open: boolean
  onClose: () => void
  userIds: string[]
  userCount: number
}

export function SendNotificationModal({ open, onClose, userIds, userCount }: SendNotificationModalProps) {
  const supabase = createClient()
  const [title, setTitle] = useState('')
  const [message, setMessage] = useState('')
  const [sending, setSending] = useState(false)

  const handleSend = async () => {
    if (!title.trim() || !message.trim()) {
      toast.error('Title and message are required')
      return
    }

    setSending(true)

    // Insert in-app notifications for all selected users
    const notifications = userIds.map((userId) => ({
      user_id: userId,
      title: title.trim(),
      message: message.trim(),
    }))

    const { error: notifError } = await supabase.from('notifications').insert(notifications)
    if (notifError) {
      toast.error('Failed to send in-app notifications')
      setSending(false)
      return
    }

    // Send push notifications via Edge Function
    try {
      await supabase.functions.invoke('send-push-notification', {
        body: { user_ids: userIds, title: title.trim(), message: message.trim() },
      })
    } catch {
      // Push may fail if FCM not configured — in-app notifications still sent
      console.warn('Push notification delivery failed — FCM may not be configured')
    }

    toast.success(`Notification sent to ${userCount} user${userCount !== 1 ? 's' : ''}`)
    setTitle('')
    setMessage('')
    setSending(false)
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Send Notification</DialogTitle>
        </DialogHeader>
        <p className="text-sm text-muted-foreground mb-4">
          Sending to <strong>{userCount}</strong> user{userCount !== 1 ? 's' : ''}. They will receive an in-app notification and push notification (if enabled).
        </p>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="notif-title">Title</Label>
            <Input id="notif-title" placeholder="e.g. Complete your order!" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="notif-message">Message</Label>
            <Textarea id="notif-message" placeholder="e.g. You left your beverage selection incomplete — come back and finish!" value={message} onChange={(e) => setMessage(e.target.value)} rows={3} />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={sending}>Cancel</Button>
          <Button onClick={handleSend} disabled={sending || !title.trim() || !message.trim()}>
            {sending ? 'Sending...' : `Send to ${userCount} user${userCount !== 1 ? 's' : ''}`}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
```

- [ ] **Step 2: Create segmented users page**

```tsx
// admin_portal/src/app/analytics/users/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { SendNotificationModal } from '@/components/send-notification-modal'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'
import { Bell } from 'lucide-react'

interface AnalyticsUser {
  id: string
  full_name: string | null
  email: string | null
  order_count: number
  last_wizard_step: number | null
  last_wizard_step_name: string | null
  last_active: string | null
  segment: string
}

export default function AnalyticsUsersPage() {
  const supabase = createClient()
  const [users, setUsers] = useState<AnalyticsUser[]>([])
  const [search, setSearch] = useState('')
  const [segment, setSegment] = useState('all')
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [modalOpen, setModalOpen] = useState(false)

  const fetchUsers = useCallback(async () => {
    // Fetch all customer profiles
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, full_name, email, role')
      .eq('role', 'customer')

    if (!profiles) { setUsers([]); return }

    // Fetch order counts per user
    const { data: orders } = await supabase
      .from('orders')
      .select('user_id')

    const orderCounts = new Map<string, number>()
    for (const o of orders ?? []) {
      orderCounts.set(o.user_id, (orderCounts.get(o.user_id) ?? 0) + 1)
    }

    // Fetch last wizard step per user
    const { data: wizardEvents } = await supabase
      .from('analytics_events')
      .select('user_id, properties, created_at')
      .eq('event_name', 'wizard_step_entered')
      .order('created_at', { ascending: false })

    const lastWizardStep = new Map<string, { step: number; name: string }>()
    for (const e of wizardEvents ?? []) {
      if (!lastWizardStep.has(e.user_id)) {
        lastWizardStep.set(e.user_id, {
          step: (e.properties as any)?.step ?? 0,
          name: (e.properties as any)?.step_name ?? '',
        })
      }
    }

    // Fetch last activity per user
    const { data: lastActivity } = await supabase
      .from('analytics_events')
      .select('user_id, created_at')
      .order('created_at', { ascending: false })

    const lastActiveMap = new Map<string, string>()
    for (const e of lastActivity ?? []) {
      if (!lastActiveMap.has(e.user_id)) {
        lastActiveMap.set(e.user_id, e.created_at)
      }
    }

    const result: AnalyticsUser[] = (profiles as any[]).map((p) => {
      const oc = orderCounts.get(p.id) ?? 0
      const ws = lastWizardStep.get(p.id)
      let seg = 'signed_up_only'
      if (oc > 0) seg = 'converted'
      else if (ws) seg = `dropped_step_${ws.step}`

      return {
        id: p.id,
        full_name: p.full_name,
        email: p.email,
        order_count: oc,
        last_wizard_step: ws?.step ?? null,
        last_wizard_step_name: ws?.name ?? null,
        last_active: lastActiveMap.get(p.id) ?? null,
        segment: seg,
      }
    })

    setUsers(result)
  }, [])

  useEffect(() => { fetchUsers() }, [fetchUsers])

  const filtered = users.filter((u) => {
    const matchesSearch = !search ||
      u.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      u.email?.toLowerCase().includes(search.toLowerCase())
    const matchesSegment = segment === 'all' || u.segment === segment ||
      (segment === 'dropped_any' && u.segment.startsWith('dropped_step_'))
    return matchesSearch && matchesSegment
  })

  const toggleSelect = (id: string) => {
    const next = new Set(selectedIds)
    if (next.has(id)) next.delete(id)
    else next.add(id)
    setSelectedIds(next)
  }

  const selectAllFiltered = () => {
    if (selectedIds.size === filtered.length) {
      setSelectedIds(new Set())
    } else {
      setSelectedIds(new Set(filtered.map((u) => u.id)))
    }
  }

  const segmentLabel = (seg: string) => {
    if (seg === 'converted') return { text: 'Converted', className: 'bg-green-100 text-green-800' }
    if (seg === 'signed_up_only') return { text: 'Signed Up Only', className: 'bg-gray-100 text-gray-600' }
    if (seg.startsWith('dropped_step_')) {
      const step = seg.replace('dropped_step_', '')
      return { text: `Dropped Step ${step}`, className: 'bg-orange-100 text-orange-800' }
    }
    return { text: seg, className: '' }
  }

  return (
    <div className="space-y-6">
      {/* Filters + Actions */}
      <div className="flex items-center gap-4 flex-wrap">
        <Input placeholder="Search name or email..." value={search} onChange={(e) => setSearch(e.target.value)} className="max-w-sm" />
        <Select value={segment} onValueChange={(v) => { setSegment(v ?? 'all'); setSelectedIds(new Set()) }}>
          <SelectTrigger className="w-52"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Users</SelectItem>
            <SelectItem value="converted">Converted</SelectItem>
            <SelectItem value="dropped_any">Dropped (any step)</SelectItem>
            <SelectItem value="dropped_step_1">Dropped Step 1</SelectItem>
            <SelectItem value="dropped_step_2">Dropped Step 2</SelectItem>
            <SelectItem value="dropped_step_3">Dropped Step 3</SelectItem>
            <SelectItem value="dropped_step_4">Dropped Step 4</SelectItem>
            <SelectItem value="dropped_step_5">Dropped Step 5</SelectItem>
            <SelectItem value="dropped_step_6">Dropped Step 6</SelectItem>
            <SelectItem value="signed_up_only">Signed Up Only</SelectItem>
          </SelectContent>
        </Select>
        {selectedIds.size > 0 && (
          <Button className="gap-2" onClick={() => setModalOpen(true)}>
            <Bell className="h-4 w-4" /> Send Notification ({selectedIds.size})
          </Button>
        )}
      </div>

      {/* Table */}
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-10">
              <input type="checkbox" checked={selectedIds.size === filtered.length && filtered.length > 0} onChange={selectAllFiltered} className="rounded" />
            </TableHead>
            <TableHead>Customer</TableHead>
            <TableHead>Segment</TableHead>
            <TableHead className="text-center">Last Step</TableHead>
            <TableHead className="text-center">Orders</TableHead>
            <TableHead>Last Active</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {filtered.map((u) => {
            const sl = segmentLabel(u.segment)
            return (
              <TableRow key={u.id}>
                <TableCell>
                  <input type="checkbox" checked={selectedIds.has(u.id)} onChange={() => toggleSelect(u.id)} className="rounded" />
                </TableCell>
                <TableCell>
                  <Link href={`/customers/${u.id}`} className="flex items-center gap-3">
                    <div className={`h-8 w-8 rounded-full ${getAvatarColor(u.full_name, u.email)} text-white flex items-center justify-center text-sm font-bold shrink-0`}>
                      {getInitials(u.full_name, u.email)}
                    </div>
                    <div>
                      <p className="font-medium">{u.full_name ?? 'Unknown'}</p>
                      <p className="text-xs text-muted-foreground">{u.email ?? 'No email'}</p>
                    </div>
                  </Link>
                </TableCell>
                <TableCell>
                  <Badge className={sl.className + ' hover:' + sl.className}>{sl.text}</Badge>
                </TableCell>
                <TableCell className="text-center">
                  {u.last_wizard_step ? `Step ${u.last_wizard_step}` : '—'}
                </TableCell>
                <TableCell className="text-center font-medium">{u.order_count}</TableCell>
                <TableCell className="text-sm text-muted-foreground">
                  {u.last_active ? new Date(u.last_active).toLocaleDateString() : '—'}
                </TableCell>
              </TableRow>
            )
          })}
          {filtered.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} className="text-center text-muted-foreground py-8">No users found</TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      {/* Notification modal */}
      <SendNotificationModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        userIds={Array.from(selectedIds)}
        userCount={selectedIds.size}
      />
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd admin_portal
git add src/app/analytics/users/page.tsx src/components/send-notification-modal.tsx
git commit -m "feat: add segmented users tab with bulk notification sending"
```

---

### Task 7: Admin analytics — activity feed tab

**Files:**
- Create: `admin_portal/src/app/analytics/activity/page.tsx`

- [ ] **Step 1: Create activity feed page**

```tsx
// admin_portal/src/app/analytics/activity/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'
import { RefreshCw } from 'lucide-react'

interface ActivityEvent {
  id: string
  user_id: string
  event_name: string
  properties: Record<string, any>
  created_at: string
  profiles?: { full_name: string | null; email: string | null } | null
}

const eventColors: Record<string, string> = {
  app_opened: 'bg-gray-100 text-gray-700',
  wizard_step_entered: 'bg-blue-100 text-blue-700',
  wizard_step_completed: 'bg-green-100 text-green-700',
  wizard_abandoned: 'bg-red-100 text-red-700',
  order_placed: 'bg-purple-100 text-purple-700',
  product_viewed: 'bg-cyan-100 text-cyan-700',
  chat_started: 'bg-amber-100 text-amber-700',
  chat_message_sent: 'bg-amber-100 text-amber-700',
  order_history_viewed: 'bg-indigo-100 text-indigo-700',
  notification_opened: 'bg-pink-100 text-pink-700',
}

function timeAgo(dateStr: string): string {
  const diffMs = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diffMs / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}

export default function AnalyticsActivityPage() {
  const supabase = createClient()
  const [events, setEvents] = useState<ActivityEvent[]>([])
  const [filter, setFilter] = useState('all')
  const [loading, setLoading] = useState(false)

  const fetchEvents = useCallback(async () => {
    setLoading(true)
    let query = supabase
      .from('analytics_events')
      .select('*, profiles(full_name, email)')
      .order('created_at', { ascending: false })
      .limit(100)

    if (filter !== 'all') query = query.eq('event_name', filter)

    const { data } = await query
    setEvents((data as ActivityEvent[]) ?? [])
    setLoading(false)
  }, [filter])

  useEffect(() => { fetchEvents() }, [fetchEvents])

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Select value={filter} onValueChange={(v) => setFilter(v ?? 'all')}>
          <SelectTrigger className="w-52"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Events</SelectItem>
            <SelectItem value="app_opened">App Opened</SelectItem>
            <SelectItem value="wizard_step_entered">Wizard Step Entered</SelectItem>
            <SelectItem value="wizard_step_completed">Wizard Step Completed</SelectItem>
            <SelectItem value="wizard_abandoned">Wizard Abandoned</SelectItem>
            <SelectItem value="order_placed">Order Placed</SelectItem>
            <SelectItem value="product_viewed">Product Viewed</SelectItem>
            <SelectItem value="chat_started">Chat Started</SelectItem>
            <SelectItem value="chat_message_sent">Chat Message Sent</SelectItem>
            <SelectItem value="order_history_viewed">Order History Viewed</SelectItem>
            <SelectItem value="notification_opened">Notification Opened</SelectItem>
          </SelectContent>
        </Select>
        <Button variant="outline" className="gap-2" onClick={fetchEvents} disabled={loading}>
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
        </Button>
      </div>

      <Card>
        <CardHeader><CardTitle>Recent Activity ({events.length})</CardTitle></CardHeader>
        <CardContent>
          {events.length === 0 ? (
            <p className="text-muted-foreground text-center py-8">No events yet</p>
          ) : (
            <div className="space-y-3">
              {events.map((e) => {
                const profile = e.profiles
                const color = eventColors[e.event_name] ?? 'bg-gray-100 text-gray-700'
                const props = e.properties ?? {}
                const propStr = Object.entries(props).map(([k, v]) => `${k}: ${v}`).join(', ')

                return (
                  <div key={e.id} className="flex items-center gap-3 py-2 border-b last:border-0">
                    <div className={`h-7 w-7 rounded-full ${getAvatarColor(profile?.full_name, profile?.email)} text-white flex items-center justify-center text-xs font-bold shrink-0`}>
                      {getInitials(profile?.full_name, profile?.email)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium">{profile?.full_name ?? profile?.email ?? 'Unknown'}</span>
                        <Badge className={`${color} text-xs`}>{e.event_name.replace(/_/g, ' ')}</Badge>
                      </div>
                      {propStr && <p className="text-xs text-muted-foreground truncate">{propStr}</p>}
                    </div>
                    <span className="text-xs text-muted-foreground shrink-0">{timeAgo(e.created_at)}</span>
                  </div>
                )
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
cd admin_portal
git add src/app/analytics/activity/page.tsx
git commit -m "feat: add activity feed tab with event filtering"
```

---

### Task 8: Sidebar update + customers page wizard drop-off

**Files:**
- Modify: `admin_portal/src/components/sidebar.tsx`
- Modify: `admin_portal/src/app/customers/page.tsx`

- [ ] **Step 1: Add Analytics to sidebar**

In `admin_portal/src/components/sidebar.tsx`, add `BarChart3` to the lucide import:

```tsx
import { LayoutDashboard, FolderTree, Package, Percent, ShoppingCart, Users, BarChart3, Wrench, Calculator, LogOut, FileText } from 'lucide-react'
```

Add Analytics nav item between Customers and Equipment:

```tsx
  { href: '/customers', label: 'Customers', icon: Users },
  { href: '/analytics', label: 'Analytics', icon: BarChart3 },
  { href: '/equipment', label: 'Equipment', icon: Wrench },
```

- [ ] **Step 2: Add wizard step column to customers page**

In `admin_portal/src/app/customers/page.tsx`, after fetching order counts, also fetch last wizard step per user from analytics_events:

After the `orderMap` building block, add:

```tsx
    // Fetch last wizard step per user
    const { data: wizardEvents } = await supabase
      .from('analytics_events')
      .select('user_id, properties')
      .eq('event_name', 'wizard_step_entered')
      .order('created_at', { ascending: false })

    const wizardMap = new Map<string, number>()
    for (const e of wizardEvents ?? []) {
      if (!wizardMap.has((e as any).user_id)) {
        wizardMap.set((e as any).user_id, (e.properties as any)?.step ?? 0)
      }
    }
```

Add `last_wizard_step` to the CustomerWithStats mapping and update the type in `src/lib/types.ts` to include `last_wizard_step?: number | null`.

In the table, add a "Last Step" column between Status and Orders:

```tsx
<TableHead className="text-center">Last Step</TableHead>
```

```tsx
<TableCell className="text-center text-sm">
  {(c as any).last_wizard_step ? `Step ${(c as any).last_wizard_step}` : '—'}
</TableCell>
```

Update the status badges to show wizard step for non-converted users:

```tsx
{c.order_count > 0 ? (
  <Badge className="bg-green-100 text-green-800 hover:bg-green-100">Converted</Badge>
) : (c as any).last_wizard_step ? (
  <Badge className="bg-orange-100 text-orange-800 hover:bg-orange-100">Step {(c as any).last_wizard_step}</Badge>
) : (
  <Badge variant="outline" className="text-muted-foreground">Not Converted</Badge>
)}
```

- [ ] **Step 3: Build and verify**

```bash
cd admin_portal && npx next build 2>&1 | tail -20
```

Expected: Build succeeds with `/analytics`, `/analytics/users`, `/analytics/activity` routes.

- [ ] **Step 4: Commit**

```bash
cd admin_portal
git add src/components/sidebar.tsx src/app/customers/page.tsx src/lib/types.ts
git commit -m "feat: add Analytics nav, wizard drop-off column to customers page"
```

---

### Task 9: Supabase Edge Function — send-push-notification

**Files:**
- Create: `supabase/functions/send-push-notification/index.ts`

- [ ] **Step 1: Create the edge function**

```ts
// supabase/functions/send-push-notification/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { user_ids, title, message } = await req.json();

    if (!user_ids?.length || !title || !message) {
      return new Response(
        JSON.stringify({ error: "user_ids, title, and message are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Use service role to bypass RLS
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Fetch device tokens for the given users
    const { data: tokens, error: tokenError } = await supabase
      .from("device_tokens")
      .select("user_id, token")
      .in("user_id", user_ids);

    if (tokenError) {
      return new Response(
        JSON.stringify({ error: "Failed to fetch device tokens" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, message: "No device tokens found for selected users" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get FCM service account key
    const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_KEY");
    if (!serviceAccountJson) {
      return new Response(
        JSON.stringify({ error: "FCM_SERVICE_ACCOUNT_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const serviceAccount = JSON.parse(serviceAccountJson);

    // Get OAuth2 access token for FCM v1 API
    const accessToken = await getAccessToken(serviceAccount);

    let sent = 0;
    const staleTokens: string[] = [];

    for (const { token } of tokens) {
      try {
        const res = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token,
                notification: { title, body: message },
              },
            }),
          }
        );

        if (res.ok) {
          sent++;
        } else {
          const err = await res.json();
          // Token is invalid or unregistered — mark for cleanup
          if (err?.error?.code === 404 || err?.error?.code === 410 ||
              err?.error?.details?.some((d: any) => d.errorCode === "UNREGISTERED")) {
            staleTokens.push(token);
          }
        }
      } catch {
        // Individual token failure — continue with others
      }
    }

    // Clean up stale tokens
    if (staleTokens.length > 0) {
      await supabase.from("device_tokens").delete().in("token", staleTokens);
    }

    return new Response(
      JSON.stringify({ sent, total: tokens.length, stale_removed: staleTokens.length }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

/**
 * Get OAuth2 access token from service account for FCM v1 API.
 * Uses the JWT grant flow.
 */
async function getAccessToken(serviceAccount: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Create JWT header and claims
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = btoa(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const unsignedJwt = `${header}.${claims}`;

  // Import private key and sign
  const pemKey = serviceAccount.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  const keyData = Uint8Array.from(atob(pemKey), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedJwt)
  );

  const signedJwt = `${unsignedJwt}.${btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "")}`;

  // Exchange JWT for access token
  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${signedJwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/send-push-notification/
git commit -m "feat: add FCM push notification edge function"
```

---

### Task 10: Flutter FCM setup + PushNotificationService

**Files:**
- Modify: `customer_app/pubspec.yaml`
- Modify: `customer_app/android/build.gradle.kts`
- Modify: `customer_app/android/app/build.gradle.kts`
- Create: `customer_app/lib/services/push_notification_service.dart`
- Modify: `customer_app/lib/main.dart`

- [ ] **Step 1: Add Firebase dependencies to pubspec.yaml**

Add under `dependencies:`:
```yaml
  firebase_core: ^3.12.1
  firebase_messaging: ^15.2.4
  flutter_local_notifications: ^18.0.1
```

Run: `cd customer_app && flutter pub get`

- [ ] **Step 2: Update Android Gradle files**

In `android/build.gradle.kts`, add Google Services classpath in `plugins`:
```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```

In `android/app/build.gradle.kts`, add plugin at top:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

Note: This requires `google-services.json` in `android/app/` — the user must provide this from Firebase Console.

- [ ] **Step 3: Create PushNotificationService**

```dart
// lib/services/push_notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  final SupabaseClient _client;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  PushNotificationService(this._client);

  Future<void> initialize() async {
    // Initialize local notifications for foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Request permission
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and register token
    final token = await messaging.getToken();
    if (token != null) await _registerToken(token);

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_registerToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  Future<void> _registerToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('device_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': 'android',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );
    } catch (_) {
      // Silent fail — token registration is not critical
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'partypour_notifications',
      'PartyPour Notifications',
      channelDescription: 'Order updates and promotions',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
```

- [ ] **Step 4: Initialize in main.dart**

In `main.dart`, add imports:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'services/push_notification_service.dart';
```

In the `main()` function, after `WidgetsFlutterBinding.ensureInitialized()` and before `runApp()`, add:
```dart
  // Initialize Firebase (requires google-services.json)
  try {
    await Firebase.initializeApp();
    final pushService = PushNotificationService(Supabase.instance.client);
    await pushService.initialize();
  } catch (e) {
    // Firebase not configured yet — skip push notifications
    debugPrint('Firebase init skipped: $e');
  }
```

The try-catch ensures the app still works without `google-services.json` during development.

- [ ] **Step 5: Commit**

```bash
cd customer_app
git add pubspec.yaml pubspec.lock android/ lib/services/push_notification_service.dart lib/main.dart
git commit -m "feat: add FCM push notification service with device token registration"
```

---

### Task 11: Build verification + deploy + Playwright test

**Files:**
- Create: `admin_portal/test-analytics.mjs`

- [ ] **Step 1: Build admin portal**

```bash
cd admin_portal && npx next build 2>&1 | tail -20
```

Expected: Build succeeds with `/analytics`, `/analytics/users`, `/analytics/activity` routes.

- [ ] **Step 2: Insert test analytics data via Supabase API**

Use the service_role key to insert sample events so the dashboard has data to show:

```bash
# Insert test events (use service_role key)
curl -s "https://wckuawushetknwpyswqm.supabase.co/rest/v1/analytics_events" \
  -H "apikey: SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '[
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"app_opened","properties":{}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_entered","properties":{"step":1,"step_name":"event"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_completed","properties":{"step":1,"step_name":"event"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_entered","properties":{"step":2,"step_name":"types"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_completed","properties":{"step":2,"step_name":"types"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_entered","properties":{"step":3,"step_name":"quantities"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_completed","properties":{"step":3,"step_name":"quantities"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_entered","properties":{"step":4,"step_name":"brands"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_completed","properties":{"step":4,"step_name":"brands"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_entered","properties":{"step":5,"step_name":"review"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_completed","properties":{"step":5,"step_name":"review"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_entered","properties":{"step":6,"step_name":"confirm"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"wizard_step_completed","properties":{"step":6,"step_name":"confirm"}},
    {"user_id":"0793416a-6710-46cf-9d9b-8595dc2d4d9a","event_name":"order_placed","properties":{"order_id":"test","amount":16980,"item_count":2}},
    {"user_id":"d0301837-ce62-4a93-8b3a-021bbfd900ce","event_name":"app_opened","properties":{}},
    {"user_id":"d0301837-ce62-4a93-8b3a-021bbfd900ce","event_name":"wizard_step_entered","properties":{"step":1,"step_name":"event"}},
    {"user_id":"d0301837-ce62-4a93-8b3a-021bbfd900ce","event_name":"wizard_step_entered","properties":{"step":2,"step_name":"types"}},
    {"user_id":"d0301837-ce62-4a93-8b3a-021bbfd900ce","event_name":"wizard_step_entered","properties":{"step":3,"step_name":"quantities"}}
  ]'
```

This creates: sadip (full funnel + converted) and Test User (dropped at step 3).

- [ ] **Step 3: Deploy to Vercel**

```bash
cd admin_portal && vercel --prod
```

- [ ] **Step 4: Write Playwright test**

```js
// admin_portal/test-analytics.mjs
import { chromium } from 'playwright'

const BASE = 'https://adminportal-five-gamma.vercel.app'

;(async () => {
  const browser = await chromium.launch({ headless: true })
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } })

  // Login
  console.log('1. Login')
  await page.goto(`${BASE}/login`)
  await page.fill('input[type="email"]', 'admin@raksichaiyo.com')
  await page.fill('input[type="password"]', 'Admin@123456')
  await page.click('button[type="submit"]')
  await page.waitForURL('**/dashboard', { timeout: 15000 })

  // Funnel tab
  console.log('2. Analytics — Funnel')
  await page.goto(`${BASE}/analytics`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-01-funnel.png', fullPage: true })

  // Users tab
  console.log('3. Analytics — Users')
  await page.goto(`${BASE}/analytics/users`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-02-users.png', fullPage: true })

  // Activity tab
  console.log('4. Analytics — Activity')
  await page.goto(`${BASE}/analytics/activity`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-03-activity.png', fullPage: true })

  // Customers page (updated with wizard step)
  console.log('5. Customers — updated')
  await page.goto(`${BASE}/customers`)
  await page.waitForTimeout(3000)
  await page.screenshot({ path: 'screenshots/analytics-04-customers.png', fullPage: true })

  await browser.close()
  console.log('Done!')
})()
```

- [ ] **Step 5: Run test and verify**

```bash
cd admin_portal && node test-analytics.mjs
```

Review screenshots to verify funnel chart, user segments, activity feed, and updated customers page.

- [ ] **Step 6: Commit**

```bash
cd admin_portal
git add test-analytics.mjs
git commit -m "test: add Playwright verification for analytics dashboard"
```

---

## Self-Review

**Spec coverage:**
- ✅ Section 1 (DB migrations): Task 1
- ✅ Section 2 (Flutter tracking): Tasks 2, 3, 4
- ✅ Section 3.1 (Funnel tab): Task 5
- ✅ Section 3.2 (Users tab + notifications): Task 6
- ✅ Section 3.3 (Activity tab): Task 7
- ✅ Section 3.4 (Sidebar): Task 8
- ✅ Section 4 (Edge Function): Task 9
- ✅ Section 5 (Customers update): Task 8
- ✅ Section 6 (Testing): Task 11
- ✅ FCM setup: Task 10

**Placeholder scan:** No TBDs, TODOs, or vague instructions found.

**Type consistency:** `AnalyticsService.trackEvent()` matches all caller signatures. `analytics_events` table columns match insert payloads. `SendNotificationModal` prop types match usage in users page.
