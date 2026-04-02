# RaksiChaiyo — Guided Wizard Ordering Flow

**Date:** 2026-04-02
**Project:** RaksiChaiyo
**Author:** Sadip / Claude

---

## 1. Overview

Replace the current free-browse-first experience with a **5-step guided wizard** that walks the customer through event-based beverage ordering. The old catalog browsing remains accessible as a secondary flow.

### New Post-Login Flow

```
Login → Step 1: Event Info
      → Step 2: Select Beverage Types
      → Step 3: Estimated Quantities (editable)
      → Step 4: Choose Specific Brands
      → Step 5: Final Review + Price → Checkout → Order Confirmed
```

Secondary: "Browse Catalog" link available from Step 1 and bottom nav → old catalog screens.

## 2. Configurable Estimation Engine

### New Database Table: `estimation_rules`

```sql
CREATE TABLE estimation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subcategory_slug TEXT NOT NULL,
  label TEXT NOT NULL,
  icon_name TEXT,
  drinks_per_guest DECIMAL(5,2) NOT NULL,
  servings_per_bottle DECIMAL(5,2) NOT NULL,
  event_multipliers JSONB NOT NULL DEFAULT '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}',
  children_factor DECIMAL(3,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Formula

```
effective_guests = (total_pax - children) + (children * children_factor)
total_servings = effective_guests * drinks_per_guest * event_multiplier[event_type]
bottles_needed = ceil(total_servings / servings_per_bottle)
```

- `children_factor = 0` for alcohol categories (children excluded)
- `children_factor = 1.0` for soft drinks (children included equally)
- `children_factor = 1.5` for juice (children drink more)

### Initial Seed Data

| Slug | Label | Drinks/Guest | Servings/Bottle | Children Factor |
|------|-------|-------------|-----------------|-----------------|
| whiskey | Whiskey | 3.0 | 12 | 0 |
| vodka | Vodka | 1.5 | 12 | 0 |
| gin | Gin | 1.0 | 12 | 0 |
| rum | Rum | 1.5 | 12 | 0 |
| brandy | Brandy | 0.5 | 12 | 0 |
| beer-bottle-can | Beer | 2.0 | 1 | 0 |
| wine | Wine | 1.0 | 5 | 0 |
| shots-specials | Shots/Specials | 1.0 | 16 | 0 |
| energy-drinks | Energy Drinks | 0.5 | 1 | 0.5 |
| cocktails | Cocktails | 1.0 | 8 | 0 |
| carbonated | Cold Drinks | 2.0 | 4 | 1.0 |
| juice | Juice | 1.0 | 4 | 1.5 |
| water | Water | 2.0 | 2 | 1.0 |
| ice-garnish | Ice | 1.0 | 10 | 1.0 |

### Admin Portal: Estimation Rules Page

New admin page at `/estimation-rules`:
- Table view of all rules with inline editing
- Edit: label, drinks_per_guest, servings_per_bottle, event_multipliers (JSON editor), children_factor
- Toggle active/inactive
- No code deployment needed to change the formula

### RLS Policies

- Everyone can read active rules (customers need them for the wizard)
- Only admins can insert/update/delete

## 3. Wizard Screens (Flutter)

### Step 1: Event Info (`wizard_event_screen.dart`)

- Progress indicator: `Step 1 of 5`
- **Total Guests** — large number with +/- stepper (min: 10, max: 2000)
- **Children** — number with +/- stepper (min: 0, max: total_pax, default: 0)
- **Event Type** — horizontal choice chips: Wedding, Birthday, Corporate, House Party, Anniversary, Other
- **Event Date** — date picker tile
- Primary "Next" button
- Secondary "Browse Catalog Instead" text link below

### Step 2: Select Beverage Types (`wizard_types_screen.dart`)

- Progress indicator: `Step 2 of 5`
- 2-column grid of selectable category cards
- Each card: icon + label, toggles on/off with checkmark overlay
- Categories fetched from `estimation_rules` where `is_active = true`
- Smart defaults: pre-select based on event type
  - Wedding: whiskey, beer, wine, cold drinks, water, ice
  - Birthday: beer, cold drinks, juice, water, ice
  - Corporate: whiskey, beer, wine, cold drinks, water
  - House Party: whiskey, vodka, beer, cold drinks, water, ice
- "Back" and "Next" buttons
- Next is disabled until at least 1 type selected

### Step 3: Estimated Quantities (`wizard_quantities_screen.dart`)

- Progress indicator: `Step 3 of 5`
- For each selected type, a card showing:
  - Category icon + name (left)
  - Estimated bottle count — large editable number with +/- stepper (right)
  - Subtitle: "~X servings for Y guests"
- Quantities calculated using estimation engine (fetches rules from Supabase)
- User can freely adjust numbers up/down (min: 0)
- "Back" and "Confirm Quantities" buttons

### Step 4: Choose Brands (`wizard_brands_screen.dart`)

- Progress indicator: `Step 4 of 5`
- Vertically scrollable, one section per selected beverage type
- Each section:
  - Category header (e.g., "Whiskey — 25 bottles needed")
  - Local / Imported segmented toggle filter
  - Grid/list of brand cards from that subcategory
  - Each brand card: name, origin badge, available sizes as chips, price per unit + per case
  - Tap to select → green check, quantity auto-filled from Step 3
  - If user selects multiple brands in same category, split quantity equally (editable)
- At least one brand per type required to proceed
- "Back" and "Next" buttons

### Step 5: Final Review (`wizard_review_screen.dart`)

- Progress indicator: `Step 5 of 5`
- Order summary grouped by category:
  - Category header
  - Each line: Brand + Size + Quantity (+/- editable) + Unit Price + Line Total
  - Subtotal per category
- Grand total section (prominent, large font)
- "Open Price Calculator" outlined button
- "Place Order" filled button → goes to checkout screen (existing, reused) with:
  - Delivery address, phone, special instructions
  - Confirm → order created

### Price Calculator (`price_calculator_screen.dart`)

- Accessible from Step 5 review or home screen
- Same card layout as Step 5 but fully interactive:
  - Change brand (dropdown per line)
  - Change size (chip selector per line)
  - Change quantity (+/-)
  - Swap between unit/case pricing
  - Real-time price recalculation
- "Apply to Order" button → pushes changes back to wizard state
- "Close" → returns to previous screen

## 4. Changes to Existing Screens

### Home Screen (`home_screen.dart`)

**Replace** the category grid as the main content. New home shows:
- "Start Your Order" prominent card/button → goes to Step 1
- Quick stats if returning: "You have an order in progress" resume card
- "Browse Catalog" secondary button → goes to old category screen
- "Price Calculator" button
- Bottom nav stays: Home, Orders, Profile

### Router Updates

New routes:
- `/wizard/event` — Step 1
- `/wizard/types` — Step 2
- `/wizard/quantities` — Step 3
- `/wizard/brands` — Step 4
- `/wizard/review` — Step 5
- `/calculator` — Price Calculator

Existing routes preserved:
- `/category/:id`, `/products/:id`, `/product/:id` — old catalog (secondary)
- `/cart`, `/checkout`, `/orders`, `/profile` — unchanged

### Planner Screen

**Remove** — replaced entirely by the wizard. The old `planner_screen.dart` and `planner_service.dart` / `planner_provider.dart` are superseded by the new estimation engine + wizard.

## 5. New State Management

### Wizard State Provider (`wizard_provider.dart`)

```dart
class WizardState {
  int totalPax;
  int childrenCount;
  String eventType;
  DateTime? eventDate;
  List<String> selectedTypeSlugs;        // from Step 2
  Map<String, int> estimatedQuantities;  // slug → bottle count, from Step 3
  Map<String, List<BrandSelection>> brandSelections; // slug → selected brands with qty
}

class BrandSelection {
  Product product;
  Variant variant;
  int quantity;
  String unitType; // 'unit' or 'case'
}
```

Persisted locally during the wizard session so the user can go back/forward without losing data.

### Estimation Service (`estimation_service.dart`)

- Fetches `estimation_rules` from Supabase (cached)
- `estimateQuantities(totalPax, children, eventType, selectedSlugs)` → `Map<String, int>`
- Pure calculation, no UI dependency

## 6. New Files Summary

### Flutter (customer_app/lib/)

| Path | Purpose |
|------|---------|
| `services/estimation_service.dart` | Fetch rules, calculate quantities |
| `providers/wizard_provider.dart` | Wizard state management |
| `screens/wizard/wizard_event_screen.dart` | Step 1: Event info |
| `screens/wizard/wizard_types_screen.dart` | Step 2: Beverage types |
| `screens/wizard/wizard_quantities_screen.dart` | Step 3: Estimated quantities |
| `screens/wizard/wizard_brands_screen.dart` | Step 4: Brand selection |
| `screens/wizard/wizard_review_screen.dart` | Step 5: Final review |
| `screens/calculator/price_calculator_screen.dart` | Price calculator |
| `widgets/step_progress.dart` | Reusable progress indicator |
| `widgets/quantity_stepper.dart` | Reusable +/- number stepper |
| `widgets/type_selector_card.dart` | Selectable category card |
| `widgets/brand_picker_card.dart` | Brand selection card |

### Modified Flutter Files

| Path | Change |
|------|--------|
| `screens/home/home_screen.dart` | Replace category grid with wizard entry point |
| `config/router.dart` | Add wizard + calculator routes |

### Removed Flutter Files

| Path | Reason |
|------|--------|
| `screens/planner/planner_screen.dart` | Replaced by wizard |
| `services/planner_service.dart` | Replaced by estimation_service |
| `providers/planner_provider.dart` | Replaced by wizard_provider |

### Supabase

| File | Purpose |
|------|---------|
| `supabase/migrations/005_estimation_rules.sql` | New table + seed data + RLS |

### Admin Portal

| Path | Purpose |
|------|---------|
| `src/app/estimation-rules/page.tsx` | CRUD for estimation rules |
| `src/components/sidebar.tsx` | Add "Estimation Rules" nav item |

## 7. UI/UX Design Principles

- **Material 3** with the existing deep orange color scheme
- **Clean, spacious layouts** — generous padding, no clutter
- **Card-based** — each logical unit in its own card with subtle elevation
- **Progress indicator** — horizontal step bar at top of every wizard screen showing current step highlighted
- **Consistent stepper widget** — rounded +/- buttons with large tappable area, number in center
- **Smooth transitions** — slide left/right animation between wizard steps
- **Sticky bottom bar** — Back/Next buttons always visible at bottom, not scrolled away
- **Origin badges** — green for Local, blue for Imported (consistent with existing)
- **Price formatting** — always "NPR X,XXX" with comma separators
- **Empty states** — friendly messages when no brands available for a category

## 8. Out of Scope

- Saving wizard progress to server (local state only, lost if app is killed)
- Multiple orders in progress simultaneously
- Brandy and Cocktails subcategories in DB (estimation rules exist but no products yet — will show "Coming Soon")
- Payment integration
