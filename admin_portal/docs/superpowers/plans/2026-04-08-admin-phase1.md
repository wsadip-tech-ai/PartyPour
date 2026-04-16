# Admin Phase 1 — Order Management & Customers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the order detail page for professional fulfillment workflow, add dispatch slip generation, build a customers page with conversion tracking, and enhance the orders list.

**Architecture:** Frontend-only upgrade to an existing Next.js 16.2.2 admin portal using shadcn/ui + Tailwind. All data comes from existing Supabase tables (orders, order_items, profiles, variants, products, notifications). No new migrations needed.

**Tech Stack:** Next.js 16 App Router, React 19, shadcn/ui, Tailwind CSS 4, Supabase SSR, Lucide icons, Playwright (testing)

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `src/lib/utils/avatar.ts` | Avatar initials + color generation |
| Create | `src/components/order-progress.tsx` | Status progress tracker bar |
| Create | `src/components/order-actions.tsx` | Contextual action buttons + print/PDF |
| Create | `src/components/customer-card.tsx` | Customer profile card with avatar |
| Create | `src/components/event-card.tsx` | Event details card with countdown |
| Create | `src/components/activity-timeline.tsx` | Order status change timeline |
| Rewrite | `src/app/orders/[id]/page.tsx` | Order detail page (stacked layout) |
| Create | `src/app/orders/[id]/dispatch-slip/page.tsx` | Print-optimized dispatch slip |
| Create | `src/app/customers/page.tsx` | Customers list with stats + table |
| Create | `src/app/customers/[id]/page.tsx` | Customer detail with order history |
| Modify | `src/components/sidebar.tsx` | Add Customers nav item |
| Modify | `src/app/orders/page.tsx` | Avatar initials + View link |
| Modify | `src/lib/types.ts` | Add CustomerWithStats type |
| Create | `test-phase1.mjs` | Playwright screenshot test for all pages |

---

### Task 1: Avatar utility + types

**Files:**
- Create: `src/lib/utils/avatar.ts`
- Modify: `src/lib/types.ts`

- [ ] **Step 1: Create avatar utility**

```ts
// src/lib/utils/avatar.ts

const colors = [
  'bg-red-500', 'bg-orange-500', 'bg-amber-500', 'bg-yellow-500',
  'bg-lime-500', 'bg-green-500', 'bg-emerald-500', 'bg-teal-500',
  'bg-cyan-500', 'bg-sky-500', 'bg-blue-500', 'bg-indigo-500',
  'bg-violet-500', 'bg-purple-500', 'bg-fuchsia-500', 'bg-pink-500',
]

export function getInitials(name?: string | null, email?: string | null): string {
  if (name && name.trim()) {
    const parts = name.trim().split(/\s+/)
    if (parts.length >= 2) return (parts[0][0] + parts[1][0]).toUpperCase()
    return parts[0][0].toUpperCase()
  }
  if (email) return email[0].toUpperCase()
  return '?'
}

export function getAvatarColor(name?: string | null, email?: string | null): string {
  const str = name || email || '?'
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash)
  }
  return colors[Math.abs(hash) % colors.length]
}
```

- [ ] **Step 2: Add CustomerWithStats type**

In `src/lib/types.ts`, append after the existing `OrderItem` interface:

```ts
export interface CustomerWithStats {
  id: string
  full_name: string | null
  email: string | null
  phone: string | null
  role: string
  created_at: string
  order_count: number
  total_spent: number
  last_order_date: string | null
}
```

- [ ] **Step 3: Commit**

```bash
git add src/lib/utils/avatar.ts src/lib/types.ts
git commit -m "feat: add avatar utility and CustomerWithStats type"
```

---

### Task 2: Order progress tracker component

**Files:**
- Create: `src/components/order-progress.tsx`

- [ ] **Step 1: Create the component**

```tsx
// src/components/order-progress.tsx
import { Check, X } from 'lucide-react'

const steps = [
  { key: 'pending', label: 'Pending' },
  { key: 'confirmed', label: 'Confirmed' },
  { key: 'dispatched', label: 'Dispatched' },
  { key: 'delivered', label: 'Delivered' },
] as const

const statusIndex: Record<string, number> = {
  pending: 0, confirmed: 1, dispatched: 2, delivered: 3, cancelled: -1,
}

const bannerStyles: Record<string, { bg: string; border: string; text: string; label: string }> = {
  pending:    { bg: 'bg-orange-50',  border: 'border-orange-300', text: 'text-orange-800', label: 'Awaiting Confirmation' },
  confirmed:  { bg: 'bg-green-50',   border: 'border-green-300',  text: 'text-green-800',  label: 'Order Confirmed' },
  dispatched: { bg: 'bg-blue-50',    border: 'border-blue-300',   text: 'text-blue-800',   label: 'Out for Delivery' },
  delivered:  { bg: 'bg-purple-50',  border: 'border-purple-300', text: 'text-purple-800', label: 'Delivered' },
  cancelled:  { bg: 'bg-red-50',     border: 'border-red-300',    text: 'text-red-800',    label: 'Order Cancelled' },
}

export function OrderProgress({ status }: { status: string }) {
  const current = statusIndex[status] ?? 0
  const isCancelled = status === 'cancelled'
  const banner = bannerStyles[status] ?? bannerStyles['pending']

  return (
    <div className={`rounded-lg border-2 px-5 py-4 ${banner.bg} ${banner.border}`}>
      <div className="flex items-center justify-between mb-3">
        <div>
          <p className={`text-xs font-semibold uppercase tracking-widest ${banner.text} opacity-70`}>Current Status</p>
          <p className={`text-2xl font-bold mt-0.5 ${banner.text}`}>{banner.label}</p>
        </div>
        <span className={`rounded-full border ${banner.border} ${banner.bg} ${banner.text} px-3 py-1 text-sm font-semibold capitalize`}>
          {status}
        </span>
      </div>

      {/* Progress bar */}
      <div className="flex items-center gap-1">
        {steps.map((step, i) => {
          const completed = !isCancelled && i <= current
          const isCurrent = !isCancelled && i === current
          return (
            <div key={step.key} className="flex-1 flex flex-col items-center gap-1">
              <div className={`w-full h-2 rounded-full transition-colors ${
                isCancelled ? 'bg-red-200' :
                completed ? 'bg-green-500' : 'bg-gray-200'
              }`} />
              <div className="flex items-center gap-1">
                {isCancelled ? (
                  <X className="h-3 w-3 text-red-400" />
                ) : completed ? (
                  <Check className="h-3 w-3 text-green-600" />
                ) : null}
                <span className={`text-xs ${
                  isCurrent ? 'font-semibold text-foreground' :
                  completed ? 'text-green-700' : 'text-muted-foreground'
                }`}>{step.label}</span>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add src/components/order-progress.tsx
git commit -m "feat: add order progress tracker component"
```

---

### Task 3: Order action buttons component

**Files:**
- Create: `src/components/order-actions.tsx`

- [ ] **Step 1: Create the component**

```tsx
// src/components/order-actions.tsx
'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { Printer, CheckCircle, XCircle, Truck, PackageCheck } from 'lucide-react'

interface OrderActionsProps {
  orderId: string
  status: string
  onStatusUpdate: () => void
}

export function OrderActions({ orderId, status, onStatusUpdate }: OrderActionsProps) {
  const supabase = createClient()
  const [loading, setLoading] = useState(false)

  const updateStatus = async (newStatus: string) => {
    setLoading(true)
    const { error } = await supabase.from('orders').update({ status: newStatus }).eq('id', orderId)
    if (error) {
      toast.error('Failed to update order status')
    } else {
      toast.success(`Order ${newStatus} successfully`)
      onStatusUpdate()
    }
    setLoading(false)
  }

  const openDispatchSlip = () => {
    window.open(`/orders/${orderId}/dispatch-slip`, '_blank')
  }

  return (
    <div className="flex items-center gap-2 flex-wrap">
      {status === 'pending' && (
        <>
          <Button className="bg-green-600 hover:bg-green-700 text-white gap-2" disabled={loading} onClick={() => updateStatus('confirmed')}>
            <CheckCircle className="h-4 w-4" /> Confirm Order
          </Button>
          <Button variant="destructive" className="gap-2" disabled={loading} onClick={() => updateStatus('cancelled')}>
            <XCircle className="h-4 w-4" /> Cancel Order
          </Button>
        </>
      )}
      {status === 'confirmed' && (
        <Button className="bg-blue-600 hover:bg-blue-700 text-white gap-2" disabled={loading} onClick={() => updateStatus('dispatched')}>
          <Truck className="h-4 w-4" /> Mark Dispatched
        </Button>
      )}
      {status === 'dispatched' && (
        <Button className="bg-purple-600 hover:bg-purple-700 text-white gap-2" disabled={loading} onClick={() => updateStatus('delivered')}>
          <PackageCheck className="h-4 w-4" /> Mark Delivered
        </Button>
      )}
      <Button variant="outline" className="gap-2" onClick={openDispatchSlip}>
        <Printer className="h-4 w-4" /> Print Dispatch Slip
      </Button>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add src/components/order-actions.tsx
git commit -m "feat: add contextual order action buttons component"
```

---

### Task 4: Customer card + Event card + Activity timeline components

**Files:**
- Create: `src/components/customer-card.tsx`
- Create: `src/components/event-card.tsx`
- Create: `src/components/activity-timeline.tsx`

- [ ] **Step 1: Create customer card**

```tsx
// src/components/customer-card.tsx
'use client'

import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Copy, ExternalLink } from 'lucide-react'
import { toast } from 'sonner'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'

interface CustomerCardProps {
  profile: { full_name: string | null; email: string | null; phone: string | null } | null
  contactPhone: string | null
  orderCount: number
  userId: string
}

export function CustomerCard({ profile, contactPhone, orderCount, userId }: CustomerCardProps) {
  const name = profile?.full_name
  const email = profile?.email
  const phone = contactPhone ?? profile?.phone
  const initials = getInitials(name, email)
  const color = getAvatarColor(name, email)

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text)
    toast.success(`${label} copied`)
  }

  return (
    <Card>
      <CardHeader><CardTitle>Customer</CardTitle></CardHeader>
      <CardContent>
        <div className="flex items-start gap-4">
          <div className={`h-12 w-12 rounded-full ${color} text-white flex items-center justify-center text-lg font-bold shrink-0`}>
            {initials}
          </div>
          <div className="space-y-1 text-sm min-w-0">
            <p className="font-semibold text-base">{name ?? 'Unknown'}</p>
            {email && (
              <p className="text-muted-foreground flex items-center gap-1">
                {email}
                <button onClick={() => copyToClipboard(email, 'Email')} className="hover:text-foreground"><Copy className="h-3 w-3" /></button>
              </p>
            )}
            {phone && (
              <p className="text-muted-foreground flex items-center gap-1">
                {phone}
                <button onClick={() => copyToClipboard(phone, 'Phone')} className="hover:text-foreground"><Copy className="h-3 w-3" /></button>
              </p>
            )}
            <div className="flex items-center gap-2 pt-1">
              <Badge variant="secondary">{orderCount} order{orderCount !== 1 ? 's' : ''} total</Badge>
              <Link href={`/customers/${userId}`} className="text-xs text-primary hover:underline inline-flex items-center gap-1">
                View profile <ExternalLink className="h-3 w-3" />
              </Link>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
```

- [ ] **Step 2: Create event card**

```tsx
// src/components/event-card.tsx
'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Copy, Calendar, Users, MapPin, Clock, PartyPopper } from 'lucide-react'
import { toast } from 'sonner'

interface EventCardProps {
  eventType: string | null
  eventDate: string | null
  guestCount: number | null
  deliveryAddress: string | null
  specialInstructions: string | null
}

const eventIcons: Record<string, string> = {
  wedding: '💒', birthday: '🎂', corporate: '🏢', house_party: '🏠', anniversary: '💑', other: '🎉',
}

function daysUntil(dateStr: string): number {
  const target = new Date(dateStr)
  const now = new Date()
  return Math.ceil((target.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
}

export function EventCard({ eventType, eventDate, guestCount, deliveryAddress, specialInstructions }: EventCardProps) {
  const days = eventDate ? daysUntil(eventDate) : null

  const copyAddress = () => {
    if (deliveryAddress) {
      navigator.clipboard.writeText(deliveryAddress)
      toast.success('Address copied')
    }
  }

  return (
    <Card>
      <CardHeader><CardTitle>Event Details</CardTitle></CardHeader>
      <CardContent className="space-y-3 text-sm">
        <div className="flex items-center gap-2">
          <PartyPopper className="h-4 w-4 text-muted-foreground" />
          <span className="font-semibold capitalize">{eventIcons[eventType ?? 'other']} {eventType ?? 'N/A'}</span>
        </div>
        <div className="flex items-center gap-2">
          <Calendar className="h-4 w-4 text-muted-foreground" />
          <span>{eventDate ?? 'N/A'}</span>
          {days !== null && days > 0 && (
            <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
              days <= 3 ? 'bg-red-100 text-red-700' :
              days <= 14 ? 'bg-orange-100 text-orange-700' :
              'bg-green-100 text-green-700'
            }`}>
              {days} day{days !== 1 ? 's' : ''} away
            </span>
          )}
          {days !== null && days <= 0 && (
            <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">Event passed</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <Users className="h-4 w-4 text-muted-foreground" />
          <span>{guestCount ?? 'N/A'} guests</span>
        </div>
        <div className="flex items-center gap-2">
          <MapPin className="h-4 w-4 text-muted-foreground" />
          <span className="flex-1">{deliveryAddress ?? 'N/A'}</span>
          {deliveryAddress && (
            <button onClick={copyAddress} className="text-muted-foreground hover:text-foreground"><Copy className="h-3 w-3" /></button>
          )}
        </div>
        {specialInstructions ? (
          <div className="flex items-start gap-2 pt-1 border-t">
            <Clock className="h-4 w-4 text-muted-foreground mt-0.5" />
            <p>{specialInstructions}</p>
          </div>
        ) : (
          <p className="text-muted-foreground italic text-xs pt-1 border-t">No special instructions</p>
        )}
      </CardContent>
    </Card>
  )
}
```

- [ ] **Step 3: Create activity timeline**

```tsx
// src/components/activity-timeline.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface TimelineEvent {
  id: string
  title: string
  message: string
  created_at: string
}

const dotColors: Record<string, string> = {
  'Confirmed': 'bg-green-500',
  'Dispatched': 'bg-blue-500',
  'Delivered': 'bg-purple-500',
  'Cancelled': 'bg-red-500',
  'Placed': 'bg-orange-500',
}

function getDotColor(title: string): string {
  for (const [key, color] of Object.entries(dotColors)) {
    if (title.toLowerCase().includes(key.toLowerCase())) return color
  }
  return 'bg-gray-400'
}

function timeAgo(dateStr: string): string {
  const now = new Date()
  const date = new Date(dateStr)
  const diffMs = now.getTime() - date.getTime()
  const mins = Math.floor(diffMs / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  if (days < 7) return `${days}d ago`
  return date.toLocaleDateString()
}

export function ActivityTimeline({ events }: { events: TimelineEvent[] }) {
  return (
    <Card>
      <CardHeader><CardTitle>Activity</CardTitle></CardHeader>
      <CardContent>
        {events.length === 0 ? (
          <p className="text-sm text-muted-foreground">No activity yet</p>
        ) : (
          <div className="space-y-3">
            {events.map((event) => (
              <div key={event.id} className="flex items-start gap-3">
                <div className={`mt-1.5 h-2.5 w-2.5 rounded-full shrink-0 ${getDotColor(event.title)}`} />
                <div className="min-w-0">
                  <p className="text-sm font-medium">{event.title}</p>
                  <p className="text-xs text-muted-foreground">{event.message}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {new Date(event.created_at).toLocaleString()} · {timeAgo(event.created_at)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
```

- [ ] **Step 4: Commit**

```bash
git add src/components/customer-card.tsx src/components/event-card.tsx src/components/activity-timeline.tsx
git commit -m "feat: add customer card, event card, and activity timeline components"
```

---

### Task 5: Rewrite order detail page

**Files:**
- Rewrite: `src/app/orders/[id]/page.tsx`

- [ ] **Step 1: Rewrite the order detail page with stacked layout**

```tsx
// src/app/orders/[id]/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { OrderProgress } from '@/components/order-progress'
import { OrderActions } from '@/components/order-actions'
import { CustomerCard } from '@/components/customer-card'
import { EventCard } from '@/components/event-card'
import { ActivityTimeline } from '@/components/activity-timeline'
import { ArrowLeft } from 'lucide-react'

interface Notification {
  id: string
  title: string
  message: string
  created_at: string
}

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const [order, setOrder] = useState<Order | null>(null)
  const [orderCount, setOrderCount] = useState(0)
  const [timeline, setTimeline] = useState<Notification[]>([])

  const fetchOrder = useCallback(async () => {
    const { data } = await supabase
      .from('orders')
      .select('*, profiles(full_name, email, phone), order_items(*, variants(size, unit_price, products(name)))')
      .eq('id', id)
      .single()
    if (data) {
      setOrder(data)
      // Fetch order count for this customer
      const { count } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', data.user_id)
      setOrderCount(count ?? 0)
      // Fetch activity timeline from notifications
      const { data: notifs } = await supabase
        .from('notifications')
        .select('id, title, message, created_at')
        .eq('order_id', id)
        .order('created_at', { ascending: false })
      setTimeline(notifs ?? [])
    }
  }, [id])

  useEffect(() => { fetchOrder() }, [fetchOrder])

  if (!order) return <div className="flex items-center justify-center h-64"><p className="text-muted-foreground">Loading order...</p></div>

  const profile = order.profiles ?? null

  return (
    <div className="max-w-4xl space-y-6">
      {/* Back link */}
      <Link href="/orders" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to Orders
      </Link>

      {/* 1. Status Banner + Progress */}
      <OrderProgress status={order.status} />

      {/* 2. Order Header + Actions */}
      <div className="flex items-start justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold">Order #{order.id.substring(0, 8)}</h1>
          <p className="text-sm text-muted-foreground">
            Placed {new Date(order.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })} at{' '}
            {new Date(order.created_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
          </p>
        </div>
        <OrderActions orderId={order.id} status={order.status} onStatusUpdate={fetchOrder} />
      </div>

      {/* 3. Customer + 4. Event — side by side on desktop */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <CustomerCard
          profile={profile}
          contactPhone={order.contact_phone}
          orderCount={orderCount}
          userId={order.user_id}
        />
        <EventCard
          eventType={order.event_type}
          eventDate={order.event_date}
          guestCount={order.guest_count}
          deliveryAddress={order.delivery_address}
          specialInstructions={order.special_instructions}
        />
      </div>

      {/* 5. Order Items */}
      <Card>
        <CardHeader><CardTitle>Items ({order.order_items?.length ?? 0} products)</CardTitle></CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead>Size</TableHead>
                <TableHead className="text-center">Qty</TableHead>
                <TableHead className="text-center">Type</TableHead>
                <TableHead className="text-right">Unit Price</TableHead>
                <TableHead className="text-right">Total</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {order.order_items?.map((item) => (
                <TableRow key={item.id}>
                  <TableCell className="font-medium">{(item as any).variants?.products?.name ?? 'N/A'}</TableCell>
                  <TableCell>{(item as any).variants?.size ?? 'N/A'}</TableCell>
                  <TableCell className="text-center">{item.quantity}</TableCell>
                  <TableCell className="text-center capitalize">{item.unit_type}</TableCell>
                  <TableCell className="text-right">NPR {item.unit_price.toLocaleString()}</TableCell>
                  <TableCell className="text-right font-medium">NPR {item.total_price.toLocaleString()}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <div className="mt-4 text-right space-y-1 border-t pt-4">
            <p className="text-sm">Subtotal: NPR {order.total_amount.toLocaleString()}</p>
            {order.discount_amount > 0 && (
              <p className="text-sm text-green-600">Discount: - NPR {order.discount_amount.toLocaleString()}</p>
            )}
            <p className="text-xl font-bold">Total: NPR {order.final_amount.toLocaleString()}</p>
          </div>
        </CardContent>
      </Card>

      {/* 6. Activity Timeline */}
      <ActivityTimeline events={timeline} />
    </div>
  )
}
```

- [ ] **Step 2: Verify build**

Run: `cd admin_portal && npx next build 2>&1 | tail -20`

Expected: Build succeeds with no errors, shows all routes including `/orders/[id]`

- [ ] **Step 3: Commit**

```bash
git add src/app/orders/[id]/page.tsx
git commit -m "feat: redesign order detail page with stacked layout"
```

---

### Task 6: Dispatch slip page

**Files:**
- Create: `src/app/orders/[id]/dispatch-slip/page.tsx`

- [ ] **Step 1: Create print-optimized dispatch slip page**

```tsx
// src/app/orders/[id]/dispatch-slip/page.tsx
import { createServerSupabase } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'

export default async function DispatchSlipPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createServerSupabase()
  const { data: order } = await supabase
    .from('orders')
    .select('*, profiles(full_name, email, phone), order_items(*, variants(size, unit_price, products(name)))')
    .eq('id', id)
    .single()

  if (!order) return notFound()

  const profile = (order as any).profiles

  return (
    <html>
      <head>
        <title>Dispatch Slip — #{order.id.substring(0, 8)}</title>
        <style>{`
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { font-family: Arial, sans-serif; padding: 40px; color: #000; background: #fff; font-size: 14px; }
          .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #000; padding-bottom: 16px; margin-bottom: 24px; }
          .logo { font-size: 24px; font-weight: bold; }
          .logo span { font-size: 12px; font-weight: normal; display: block; color: #666; }
          .slip-title { font-size: 20px; font-weight: bold; text-transform: uppercase; letter-spacing: 2px; }
          .meta { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px; }
          .meta-section h3 { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #666; margin-bottom: 8px; border-bottom: 1px solid #ddd; padding-bottom: 4px; }
          .meta-section p { margin-bottom: 4px; }
          .meta-section p strong { display: inline-block; width: 100px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
          th { background: #f5f5f5; text-align: left; padding: 8px 12px; border: 1px solid #ddd; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; }
          td { padding: 8px 12px; border: 1px solid #ddd; }
          .total-row td { font-weight: bold; font-size: 16px; background: #f9f9f9; }
          .instructions { background: #f9f9f9; border: 1px solid #ddd; padding: 12px; margin-bottom: 24px; border-radius: 4px; }
          .instructions h3 { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #666; margin-bottom: 8px; }
          .sign-off { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 24px; margin-top: 40px; padding-top: 24px; border-top: 1px solid #ddd; }
          .sign-off div { border-bottom: 1px solid #000; padding-bottom: 30px; }
          .sign-off label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #666; }
          .print-btn { position: fixed; top: 16px; right: 16px; background: #000; color: #fff; border: none; padding: 10px 24px; font-size: 14px; cursor: pointer; border-radius: 6px; }
          @media print {
            .print-btn { display: none; }
            body { padding: 20px; }
          }
        `}</style>
      </head>
      <body>
        <button className="print-btn" onClick="window.print()">Print / Save PDF</button>

        <div className="header">
          <div className="logo">
            PartyPour
            <span>Beverage Service</span>
          </div>
          <div className="slip-title">Dispatch Slip</div>
        </div>

        <div className="meta">
          <div className="meta-section">
            <h3>Order Information</h3>
            <p><strong>Order ID:</strong> #{order.id.substring(0, 8)}</p>
            <p><strong>Order Date:</strong> {new Date(order.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
            <p><strong>Status:</strong> {order.status.toUpperCase()}</p>
          </div>
          <div className="meta-section">
            <h3>Customer</h3>
            <p><strong>Name:</strong> {profile?.full_name ?? 'N/A'}</p>
            <p><strong>Phone:</strong> {order.contact_phone ?? profile?.phone ?? 'N/A'}</p>
            <p><strong>Address:</strong> {order.delivery_address ?? 'N/A'}</p>
          </div>
        </div>

        <div className="meta">
          <div className="meta-section">
            <h3>Event</h3>
            <p><strong>Type:</strong> {order.event_type ?? 'N/A'}</p>
            <p><strong>Date:</strong> {order.event_date ?? 'N/A'}</p>
            <p><strong>Guests:</strong> {order.guest_count ?? 'N/A'}</p>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>#</th>
              <th>Product</th>
              <th>Size</th>
              <th>Qty</th>
              <th>Type</th>
              <th style={{ textAlign: 'right' }}>Total</th>
            </tr>
          </thead>
          <tbody>
            {order.order_items?.map((item: any, i: number) => (
              <tr key={item.id}>
                <td>{i + 1}</td>
                <td>{item.variants?.products?.name ?? 'N/A'}</td>
                <td>{item.variants?.size ?? 'N/A'}</td>
                <td>{item.quantity}</td>
                <td>{item.unit_type}</td>
                <td style={{ textAlign: 'right' }}>NPR {item.total_price.toLocaleString()}</td>
              </tr>
            ))}
            <tr className="total-row">
              <td colSpan={5} style={{ textAlign: 'right' }}>TOTAL</td>
              <td style={{ textAlign: 'right' }}>NPR {order.final_amount.toLocaleString()}</td>
            </tr>
          </tbody>
        </table>

        {order.special_instructions && (
          <div className="instructions">
            <h3>Special Instructions</h3>
            <p>{order.special_instructions}</p>
          </div>
        )}

        <div className="sign-off">
          <div><label>Prepared by</label></div>
          <div><label>Checked by</label></div>
          <div><label>Date</label></div>
        </div>
      </body>
    </html>
  )
}
```

**Note:** This page renders as a standalone HTML document (no layout/sidebar) since it's meant for printing. The `<html>` wrapper overrides the root layout. Use JSX attributes (`className`, `onClick` as string for the button since it's server-rendered — replace with a client component wrapper if needed).

- [ ] **Step 2: Fix the print button interactivity**

The dispatch slip is server-rendered but needs a client-side print button. The simplest fix: use a `<script>` tag in the page or convert the button. Since this is a standalone print page, use dangerouslySetInnerHTML for the script:

Replace the `<button>` line with:

```tsx
<button
  id="print-btn"
  style={{ position: 'fixed', top: 16, right: 16, background: '#000', color: '#fff', border: 'none', padding: '10px 24px', fontSize: 14, cursor: 'pointer', borderRadius: 6 }}
>
  Print / Save PDF
</button>
<script dangerouslySetInnerHTML={{ __html: `document.getElementById('print-btn').onclick = function() { window.print(); }` }} />
```

And remove the `className` and `onClick` from the original button.

- [ ] **Step 3: Verify build**

Run: `cd admin_portal && npx next build 2>&1 | tail -20`

Expected: Build succeeds, `/orders/[id]/dispatch-slip` appears as a dynamic route

- [ ] **Step 4: Commit**

```bash
git add src/app/orders/[id]/dispatch-slip/page.tsx
git commit -m "feat: add print-optimized dispatch slip page"
```

---

### Task 7: Customers list page

**Files:**
- Create: `src/app/customers/page.tsx`

- [ ] **Step 1: Create customers page**

```tsx
// src/app/customers/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { CustomerWithStats } from '@/lib/types'
import { StatCard } from '@/components/stat-card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Users, UserCheck, UserX } from 'lucide-react'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'

export default function CustomersPage() {
  const supabase = createClient()
  const [customers, setCustomers] = useState<CustomerWithStats[]>([])
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const fetchCustomers = useCallback(async () => {
    // Fetch profiles with order stats using RPC or manual join
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, full_name, email, phone, role, created_at')
      .eq('role', 'customer')
      .order('created_at', { ascending: false })

    if (!profiles) { setCustomers([]); return }

    // Fetch order counts per user
    const { data: orders } = await supabase
      .from('orders')
      .select('user_id, final_amount')

    const orderMap = new Map<string, { count: number; total: number; lastDate: string }>()
    for (const o of orders ?? []) {
      const existing = orderMap.get(o.user_id) ?? { count: 0, total: 0, lastDate: '' }
      existing.count++
      existing.total += o.final_amount ?? 0
      orderMap.set(o.user_id, existing)
    }

    const result: CustomerWithStats[] = profiles.map((p) => {
      const stats = orderMap.get(p.id) ?? { count: 0, total: 0, lastDate: null }
      return {
        ...p,
        order_count: stats.count,
        total_spent: stats.total,
        last_order_date: stats.lastDate || null,
      }
    })

    setCustomers(result)
  }, [])

  useEffect(() => { fetchCustomers() }, [fetchCustomers])

  const filtered = customers.filter((c) => {
    const matchesSearch = !search ||
      (c.full_name?.toLowerCase().includes(search.toLowerCase())) ||
      (c.email?.toLowerCase().includes(search.toLowerCase()))
    const matchesStatus = statusFilter === 'all' ||
      (statusFilter === 'converted' && c.order_count > 0) ||
      (statusFilter === 'not_converted' && c.order_count === 0)
    return matchesSearch && matchesStatus
  })

  const totalUsers = customers.length
  const converted = customers.filter((c) => c.order_count > 0).length
  const notConverted = totalUsers - converted

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Customers</h1>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <StatCard title="Total Users" value={totalUsers} icon={Users} />
        <StatCard title="Converted" value={converted} icon={UserCheck} description="Placed at least 1 order" />
        <StatCard title="Not Converted" value={notConverted} icon={UserX} description="Signed up but no orders" />
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4 mb-6">
        <Input
          placeholder="Search by name or email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-sm"
        />
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v ?? 'all')}>
          <SelectTrigger className="w-48"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Customers</SelectItem>
            <SelectItem value="converted">Converted</SelectItem>
            <SelectItem value="not_converted">Not Converted</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* Table */}
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Customer</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="text-center">Orders</TableHead>
            <TableHead className="text-right">Total Spent</TableHead>
            <TableHead>Joined</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {filtered.map((c) => (
            <TableRow key={c.id} className="cursor-pointer hover:bg-muted/50">
              <TableCell>
                <Link href={`/customers/${c.id}`} className="flex items-center gap-3">
                  <div className={`h-8 w-8 rounded-full ${getAvatarColor(c.full_name, c.email)} text-white flex items-center justify-center text-sm font-bold shrink-0`}>
                    {getInitials(c.full_name, c.email)}
                  </div>
                  <div>
                    <p className="font-medium">{c.full_name ?? 'Unknown'}</p>
                    <p className="text-xs text-muted-foreground">{c.email ?? 'No email'}</p>
                  </div>
                </Link>
              </TableCell>
              <TableCell>
                {c.order_count > 0 ? (
                  <Badge className="bg-green-100 text-green-800 hover:bg-green-100">Converted</Badge>
                ) : (
                  <Badge variant="outline" className="text-muted-foreground">Not Converted</Badge>
                )}
              </TableCell>
              <TableCell className="text-center font-medium">{c.order_count}</TableCell>
              <TableCell className="text-right">{c.total_spent > 0 ? `NPR ${c.total_spent.toLocaleString()}` : '—'}</TableCell>
              <TableCell className="text-muted-foreground text-sm">{new Date(c.created_at).toLocaleDateString()}</TableCell>
            </TableRow>
          ))}
          {filtered.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} className="text-center text-muted-foreground py-8">No customers found</TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add src/app/customers/page.tsx
git commit -m "feat: add customers list page with stats and filtering"
```

---

### Task 8: Customer detail page

**Files:**
- Create: `src/app/customers/[id]/page.tsx`

- [ ] **Step 1: Create customer detail page**

```tsx
// src/app/customers/[id]/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { StatCard } from '@/components/stat-card'
import { ArrowLeft, ShoppingCart, DollarSign, TrendingUp, Calendar } from 'lucide-react'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'

interface Profile {
  id: string
  full_name: string | null
  email: string | null
  phone: string | null
  role: string
  created_at: string
}

const statusColors: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  pending: 'outline',
  confirmed: 'secondary',
  dispatched: 'default',
  delivered: 'default',
  cancelled: 'destructive',
}

export default function CustomerDetailPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [orders, setOrders] = useState<Order[]>([])

  const fetchData = useCallback(async () => {
    const [{ data: profileData }, { data: ordersData }] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', id).single(),
      supabase.from('orders').select('*').eq('user_id', id).order('created_at', { ascending: false }),
    ])
    if (profileData) setProfile(profileData)
    setOrders(ordersData ?? [])
  }, [id])

  useEffect(() => { fetchData() }, [fetchData])

  if (!profile) return <div className="flex items-center justify-center h-64"><p className="text-muted-foreground">Loading...</p></div>

  const totalSpent = orders.reduce((sum, o) => sum + (o.final_amount ?? 0), 0)
  const avgOrder = orders.length > 0 ? totalSpent / orders.length : 0
  const eventTypes = orders.map((o) => o.event_type).filter(Boolean)
  const favoriteEvent = eventTypes.length > 0
    ? eventTypes.sort((a, b) => eventTypes.filter(e => e === a).length - eventTypes.filter(e => e === b).length).pop()
    : null

  const initials = getInitials(profile.full_name, profile.email)
  const color = getAvatarColor(profile.full_name, profile.email)

  return (
    <div className="max-w-4xl space-y-6">
      <Link href="/customers" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to Customers
      </Link>

      {/* Profile Card */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className={`h-16 w-16 rounded-full ${color} text-white flex items-center justify-center text-2xl font-bold shrink-0`}>
              {initials}
            </div>
            <div className="space-y-1">
              <h1 className="text-2xl font-bold">{profile.full_name ?? 'Unknown'}</h1>
              <p className="text-muted-foreground">{profile.email ?? 'No email'}</p>
              {profile.phone && <p className="text-muted-foreground">{profile.phone}</p>}
              <div className="flex items-center gap-2 pt-1">
                {orders.length > 0 ? (
                  <Badge className="bg-green-100 text-green-800 hover:bg-green-100">Converted</Badge>
                ) : (
                  <Badge variant="outline" className="text-muted-foreground">Not Converted</Badge>
                )}
                <span className="text-xs text-muted-foreground">
                  Joined {new Date(profile.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}
                </span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard title="Total Orders" value={orders.length} icon={ShoppingCart} />
        <StatCard title="Total Spent" value={`NPR ${totalSpent.toLocaleString()}`} icon={DollarSign} />
        <StatCard title="Avg Order" value={`NPR ${Math.round(avgOrder).toLocaleString()}`} icon={TrendingUp} />
        <StatCard title="Favorite Event" value={favoriteEvent ?? 'N/A'} icon={Calendar} />
      </div>

      {/* Order History */}
      <Card>
        <CardHeader><CardTitle>Order History</CardTitle></CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Order ID</TableHead>
                <TableHead>Event</TableHead>
                <TableHead className="text-right">Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Date</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {orders.map((order) => (
                <TableRow key={order.id}>
                  <TableCell>
                    <Link href={`/orders/${order.id}`} className="text-primary hover:underline">
                      #{order.id.substring(0, 8)}
                    </Link>
                  </TableCell>
                  <TableCell className="capitalize">{order.event_type ?? '—'}</TableCell>
                  <TableCell className="text-right font-medium">NPR {order.final_amount.toLocaleString()}</TableCell>
                  <TableCell>
                    <Badge variant={statusColors[order.status] ?? 'default'}>{order.status}</Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{new Date(order.created_at).toLocaleDateString()}</TableCell>
                </TableRow>
              ))}
              {orders.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground py-8">No orders yet</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add src/app/customers/[id]/page.tsx
git commit -m "feat: add customer detail page with order history"
```

---

### Task 9: Sidebar + orders list enhancements

**Files:**
- Modify: `src/components/sidebar.tsx`
- Modify: `src/app/orders/page.tsx`

- [ ] **Step 1: Add Customers to sidebar**

In `src/components/sidebar.tsx`, add `Users` to the import from lucide-react:

```tsx
import { LayoutDashboard, FolderTree, Package, Percent, ShoppingCart, Wrench, Calculator, LogOut, FileText, Users } from 'lucide-react'
```

Add the Customers nav item in the `navItems` array, after the Orders entry:

```tsx
  { href: '/orders', label: 'Orders', icon: ShoppingCart },
  { href: '/customers', label: 'Customers', icon: Users },
  { href: '/equipment', label: 'Equipment', icon: Wrench },
```

- [ ] **Step 2: Enhance orders list page**

In `src/app/orders/page.tsx`, add imports at the top:

```tsx
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'
import { Eye } from 'lucide-react'
```

Replace the customer `<TableCell>` (the one showing `order.profiles?.full_name`) with an avatar version:

```tsx
<TableCell>
  <div className="flex items-center gap-2">
    <div className={`h-6 w-6 rounded-full ${getAvatarColor(order.profiles?.full_name, order.profiles?.email)} text-white flex items-center justify-center text-xs font-bold shrink-0`}>
      {getInitials(order.profiles?.full_name, order.profiles?.email)}
    </div>
    <span>{order.profiles?.full_name ?? order.profiles?.email ?? 'Unknown'}</span>
  </div>
</TableCell>
```

In the Actions `<TableCell>`, add a View button before the status-specific actions:

```tsx
<TableCell>
  <div className="flex items-center gap-2">
    <Link href={`/orders/${order.id}`}>
      <Button size="sm" variant="outline" className="h-7 px-3 text-xs gap-1">
        <Eye className="h-3 w-3" /> View
      </Button>
    </Link>
    {order.status === 'pending' ? (
      <>
        <Button
          size="sm"
          className="bg-green-600 hover:bg-green-700 text-white h-7 px-3 text-xs"
          disabled={actionLoading !== null}
          onClick={() => quickUpdateStatus(order.id, 'confirmed')}
        >
          {actionLoading === order.id + 'confirmed' ? '...' : 'Confirm'}
        </Button>
        <Button
          size="sm"
          variant="destructive"
          className="h-7 px-3 text-xs"
          disabled={actionLoading !== null}
          onClick={() => quickUpdateStatus(order.id, 'cancelled')}
        >
          {actionLoading === order.id + 'cancelled' ? '...' : 'Cancel'}
        </Button>
      </>
    ) : (
      <span className="text-muted-foreground text-xs">—</span>
    )}
  </div>
</TableCell>
```

Also add missing imports at the top of the file if not already present: `import Link from 'next/link'` (already imported) and `import { Eye } from 'lucide-react'`.

- [ ] **Step 3: Verify build**

Run: `cd admin_portal && npx next build 2>&1 | tail -20`

Expected: Build succeeds with `/customers`, `/customers/[id]` appearing as new routes

- [ ] **Step 4: Commit**

```bash
git add src/components/sidebar.tsx src/app/orders/page.tsx
git commit -m "feat: add customers nav + avatar initials and view button to orders list"
```

---

### Task 10: Playwright end-to-end verification

**Files:**
- Create: `test-phase1.mjs`

- [ ] **Step 1: Write Playwright test**

```js
// test-phase1.mjs
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
  await page.screenshot({ path: 'screenshots/phase1-01-dashboard.png', fullPage: true })
  console.log('  -> Dashboard OK')

  // Orders list
  console.log('2. Orders list')
  await page.click('a[href="/orders"]')
  await page.waitForURL('**/orders')
  await page.waitForTimeout(2000)
  await page.screenshot({ path: 'screenshots/phase1-02-orders-list.png', fullPage: true })
  console.log('  -> Orders list OK')

  // Order detail
  console.log('3. Order detail')
  const orderLink = page.locator('a[href^="/orders/"][href$!="orders"]').first()
  if (await orderLink.isVisible()) {
    await orderLink.click()
    await page.waitForTimeout(3000)
    await page.screenshot({ path: 'screenshots/phase1-03-order-detail.png', fullPage: true })
    console.log('  -> Order detail OK')

    // Dispatch slip
    console.log('4. Dispatch slip')
    const [slipPage] = await Promise.all([
      page.context().waitForEvent('page'),
      page.click('button:has-text("Print Dispatch Slip")'),
    ])
    await slipPage.waitForLoadState()
    await slipPage.waitForTimeout(2000)
    await slipPage.screenshot({ path: 'screenshots/phase1-04-dispatch-slip.png', fullPage: true })
    await slipPage.close()
    console.log('  -> Dispatch slip OK')
  }

  // Customers list
  console.log('5. Customers list')
  await page.click('a[href="/customers"]')
  await page.waitForURL('**/customers')
  await page.waitForTimeout(2000)
  await page.screenshot({ path: 'screenshots/phase1-05-customers.png', fullPage: true })
  console.log('  -> Customers OK')

  // Customer detail
  console.log('6. Customer detail')
  const customerLink = page.locator('a[href^="/customers/"]').first()
  if (await customerLink.isVisible()) {
    await customerLink.click()
    await page.waitForTimeout(3000)
    await page.screenshot({ path: 'screenshots/phase1-06-customer-detail.png', fullPage: true })
    console.log('  -> Customer detail OK')
  }

  await browser.close()
  console.log('Done! All screenshots in screenshots/')
})()
```

- [ ] **Step 2: Deploy and test**

```bash
cd admin_portal
vercel --prod
node test-phase1.mjs
```

- [ ] **Step 3: Review screenshots**

Open each screenshot and verify:
- Orders list shows avatar initials + View button
- Order detail has: progress tracker, action buttons, customer card, event card, items, timeline
- Dispatch slip is clean print layout
- Customers page has stat cards + table with badges
- Customer detail shows profile + order history

- [ ] **Step 4: Commit test**

```bash
git add test-phase1.mjs
git commit -m "test: add Playwright e2e verification for Phase 1"
```

---

## Self-Review Checklist

- **Spec coverage**: All 5 spec sections covered (order detail ✓, dispatch slip ✓, customers ✓, sidebar ✓, orders list ✓)
- **Placeholders**: None — all code is complete
- **Type consistency**: `CustomerWithStats` defined in Task 1, used in Task 7. `Order` type reused from existing types. `getInitials`/`getAvatarColor` defined in Task 1, used in Tasks 4, 5, 7, 8, 9.
- **File paths**: All match existing project structure (`src/app/`, `src/components/`, `src/lib/`)
