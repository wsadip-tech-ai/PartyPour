# Admin Portal Phase 1 — Order Management & Customers

## Overview

Redesign the order detail page for professional order fulfillment workflow, add a customers page for user management and conversion tracking, and add dispatch slip generation. This is Phase 1 of a 5-phase admin upgrade.

## Architecture

- **Framework**: Next.js 16.2.2 (App Router, Turbopack)
- **UI**: shadcn/ui components + Tailwind CSS
- **Data**: Supabase (existing tables: orders, order_items, profiles, variants, products, notifications)
- **Auth**: Supabase SSR with `proxy.ts` session refresh (just added)
- **Deployment**: Vercel (https://adminportal-five-gamma.vercel.app)

No new database tables needed for Phase 1. All data already exists — this is a frontend-only upgrade.

## 1. Order Detail Page Redesign

**Layout**: Stacked sections (full-width cards, vertical scroll)

### Components (top to bottom):

#### 1.1 Status Banner + Progress Tracker
- Full-width colored banner showing current status (reuse existing color scheme)
- Horizontal progress dots/bar: Pending → Confirmed → Dispatched → Delivered
- Each completed step shows a checkmark, current step is highlighted, future steps are gray
- If cancelled, show red banner with strikethrough on progress

#### 1.2 Order Header
- Order ID (short hash) + full timestamp ("Placed Apr 8, 2026 at 11:37 AM")
- Right side: contextual primary action button + print/PDF buttons
  - Pending → "Confirm Order" (green) + "Cancel Order" (red)
  - Confirmed → "Mark Dispatched" (blue)
  - Dispatched → "Mark Delivered" (purple)
  - Delivered → no action button (completed state)
  - Cancelled → no action button
- Print button: opens dispatch slip in new tab (print-optimized)
- PDF button: downloads dispatch slip as PDF

#### 1.3 Customer Card
- Avatar with initials (colored based on first letter hash)
- Full name, email, phone (with click-to-copy)
- Badge showing total order count for this customer ("3 orders total")
- Link: "View all orders by this customer" → filters orders list page

#### 1.4 Event Details Card
- Event type (Wedding, Birthday, etc.) with icon
- Event date with relative countdown ("7 days away" in orange if < 14 days)
- Guest count
- Delivery address (with copy button)
- Special instructions (if any, italic gray if none)

#### 1.5 Order Items Table
- Columns: Product name, Size, Qty, Unit Type (unit/case), Unit Price, Total
- Product name from joined variants → products relationship
- Row subtotals
- Footer: Subtotal, Discount, **Total** (bold, larger)

#### 1.6 Activity Timeline
- Vertical timeline showing every status change with timestamp
- Format: colored dot + status label + "by Admin" + relative time
- Most recent at top
- Data source: query `notifications` table filtered by this order_id (the trigger already creates records for each status change)

#### 1.7 Status Update (collapsed by default)
- Expandable section with manual status dropdown + update button
- Only shown for non-terminal states (not delivered/cancelled)
- Secondary to the contextual action buttons above

### Data Query
Existing query already fetches everything needed:
```
orders → profiles(full_name, email, phone)
       → order_items → variants(size, unit_price) → products(name)
```
Add: count of orders by same user_id, notifications for this order_id.

## 2. Dispatch Slip / Packing List

### Content
- PartyPour logo + "Dispatch Slip" header
- Order ID, order date
- Customer: name, phone, delivery address
- Event: type, date, guest count
- Items table: product name, size, quantity, unit type
- Special instructions (if any)
- Footer: "Prepared by: _____ | Checked by: _____ | Date: _____"

### Implementation
- New route: `/orders/[id]/dispatch-slip` — server-rendered, print-optimized page
  - `@media print` styles, no sidebar/nav, clean black-on-white
  - Accessible via "Print" button on order detail (opens in new tab)
- PDF generation approach: use `window.print()` for both print and PDF. The dispatch slip page has print-optimized CSS. Users click "Print" to open the slip, then either print physically or use Chrome's "Save as PDF" option. No extra PDF libraries needed — keeps dependencies minimal.

## 3. Customers Page

**Layout**: Summary stat cards + searchable data table

### Route: `/customers`

### 3.1 Summary Stats (top row, 4 cards)
- Total Users (count of profiles)
- Converted (users with at least 1 order)
- In Wizard (users with analytics events showing wizard entry but no order — Phase 5 dependency, show placeholder for now)
- Signed Up Only (users with 0 orders and no wizard activity)

Note: "In Wizard" and wizard drop-off tracking requires the analytics_events table from Phase 5. For Phase 1, show only two categories: "Converted" (has orders) and "Not Converted" (no orders). Add wizard tracking column later.

### 3.2 Filters
- Search by name/email
- Filter by status: All | Converted | Not Converted

### 3.3 Data Table
- Columns: Customer (avatar + name + email), Status (badge), Orders (count), Total Spent, Last Order Date
- Click row → navigate to customer detail page

### 3.4 Customer Detail Page (`/customers/[id]`)
- Customer profile card (name, email, phone, account created date)
- Conversion status badge
- Order history table (reuse order list table design, filtered to this user)
- Stats: total orders, total spent, average order value, favorite event type

### Data Query
```sql
-- Customers list with order stats
SELECT p.*, 
  COUNT(o.id) as order_count,
  COALESCE(SUM(o.final_amount), 0) as total_spent,
  MAX(o.created_at) as last_order_date
FROM profiles p
LEFT JOIN orders o ON o.user_id = p.id
WHERE p.role = 'customer'
GROUP BY p.id
```

## 4. Sidebar Update

Add "Customers" nav item to sidebar between "Orders" and "Equipment":
```
{ href: '/customers', label: 'Customers', icon: Users }
```

## 5. Orders List Page — Minor Enhancements

- Add customer avatar initials next to name
- Show order total more prominently
- Add "View" link in actions column (in addition to confirm/cancel for pending)

## Testing

- Use Playwright CLI scripts to screenshot all pages after implementation
- Verify: login → dashboard → orders list → order detail → dispatch slip → customers → customer detail
- Test status transitions: pending → confirmed → dispatched → delivered
- Test print/PDF generation

## Out of Scope (Later Phases)

- Push notifications (Phase 3)
- Email confirmations (Phase 4)
- Analytics events table + wizard funnel tracking (Phase 5)
- Dashboard charts and trends (Phase 5)
