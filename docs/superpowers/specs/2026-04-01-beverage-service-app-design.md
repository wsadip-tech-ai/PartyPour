# Beverage Service App — Design Spec

**Date:** 2026-04-01
**Project:** PilaoPani (working title)
**Author:** Sadip / Claude

---

## 1. Problem Statement

In Nepal, event organizers (weddings, birthdays, anniversaries, corporate events, house parties) are responsible for sourcing their own beverages. There's no streamlined way to browse, select, and order event-quantity beverages with transparent pricing. This app solves that by offering a curated catalog of hard drinks, soft drinks, mixers, and draught beer equipment — with per-unit and per-case pricing, a guest-count estimator, and home delivery.

## 2. Business Model

- **Supply-focused:** Sell beverages (soft + hard drinks) and rent draught beer equipment
- **Revenue:** Margin on beverage sales + equipment rental fees
- **No bartending service** in initial scope

## 3. Target Users

- **Customers:** Event organizers in Nepal planning events of 20–1000+ guests (weddings, birthdays, anniversaries, corporate events, house parties)
- **Admins:** Business operators managing catalog, pricing, orders, and inventory

## 4. Tech Stack

| Component | Technology |
|-----------|-----------|
| Customer App | Flutter + Dart (Android + iOS) |
| Admin Portal | Web-based (React/Next.js or Flutter Web) |
| Backend | Supabase (Auth, Database, Storage, Edge Functions) |
| Database | PostgreSQL (via Supabase) |

## 5. Product Hierarchy

### Structure
```
Category → Subcategory → Product → Variant (size/unit)
```

- **2-level category hierarchy** (Category → Subcategory)
- **Origin** (Local / Imported) is a filterable attribute on products, not a hierarchy level
- **Tags** for additional filtering (e.g., "premium", "budget", "popular")

### Categories & Subcategories

```
├── Hard Drinks
│   ├── Whiskey
│   ├── Vodka
│   ├── Rum
│   ├── Wine
│   ├── Beer (Bottle/Can)
│   ├── Beer (Draught)
│   └── Gin
├── Soft Drinks
│   ├── Carbonated
│   ├── Juice
│   ├── Water
│   └── Energy Drinks
├── Mixers & Add-ons
│   ├── Mixers
│   └── Ice & Garnish
└── Equipment (Rental)
    └── Draught Beer Setup
```

## 6. Initial Product Catalog (~30 products)

### Hard Drinks — Whiskey

| Brand | Origin | Sizes |
|-------|--------|-------|
| Khukuri | Local | 750ml, 375ml |
| Ruslan | Local | 750ml, 375ml |
| Mt. Everest | Local | 750ml, 375ml |
| Old Durbar | Local | 750ml, 375ml |
| Johnnie Walker Red Label | Imported | 750ml, 1L |
| Johnnie Walker Black Label | Imported | 750ml, 1L |
| 100 Pipers | Imported | 750ml |

### Hard Drinks — Vodka

| Brand | Origin | Sizes |
|-------|--------|-------|
| Ruslan Vodka | Local | 750ml, 375ml |
| Absolut | Imported | 750ml, 1L |
| Smirnoff | Imported | 750ml |

### Hard Drinks — Rum

| Brand | Origin | Sizes |
|-------|--------|-------|
| Khukuri Rum | Local | 750ml, 375ml |
| Old Monk | Imported | 750ml |
| Bacardi | Imported | 750ml |

### Hard Drinks — Wine

| Brand | Origin | Sizes |
|-------|--------|-------|
| Hinwa (Red/White) | Local | 750ml |
| Jacob's Creek (Red/White) | Imported | 750ml |
| Carlo Rossi (Red/White) | Imported | 750ml |

### Hard Drinks — Gin

| Brand | Origin | Sizes |
|-------|--------|-------|
| Sherpa Gin | Local | 750ml |
| Gordon's | Imported | 750ml |

### Hard Drinks — Beer (Bottle/Can)

| Brand | Origin | Sizes |
|-------|--------|-------|
| Gorkha | Local | 650ml, 330ml |
| Tuborg | Local | 650ml, 330ml |
| Nepal Ice | Local | 650ml, 330ml |
| Carlsberg | Local | 650ml, 330ml |
| Budweiser | Imported | 330ml |

### Hard Drinks — Beer (Draught)

| Brand | Origin | Unit |
|-------|--------|------|
| Gorkha Draught | Local | 20L Keg, 50L Keg |
| Tuborg Draught | Local | 20L Keg, 50L Keg |

### Soft Drinks — Carbonated

| Brand | Origin | Sizes |
|-------|--------|-------|
| Coca-Cola | Imported | 2.25L, 500ml, 300ml |
| Fanta | Imported | 2.25L, 500ml |
| Sprite | Imported | 2.25L, 500ml |
| Real Gold Soda | Local | 300ml |

### Soft Drinks — Juice

| Brand | Origin | Sizes |
|-------|--------|-------|
| Real | Imported | 1L |
| Frooti | Imported | 1L, 200ml |
| Local Fresh Juice | Local | 1L |

### Soft Drinks — Water

| Brand | Origin | Sizes |
|-------|--------|-------|
| Aqua Nepal | Local | 20L, 1L, 500ml |
| Himalayan | Local | 1L, 500ml |

### Soft Drinks — Energy Drinks

| Brand | Origin | Sizes |
|-------|--------|-------|
| Red Bull | Imported | 250ml |
| Sting | Imported | 250ml |

### Mixers & Add-ons — Mixers

| Item | Sizes |
|------|-------|
| Tonic Water | 500ml |
| Soda Water | 500ml |
| Ginger Ale | 330ml |
| Lime Cordial | 750ml |

### Mixers & Add-ons — Ice & Garnish

| Item | Unit |
|------|------|
| Ice (Cubed) | 5kg bag |
| Lemon/Lime | Per kg |
| Mint | Per bunch |

### Equipment (Rental) — Draught Beer Setup

| Item | Unit |
|------|------|
| Draught Beer Dispenser | Per event |
| CO2 Cylinder | Per unit |
| Draught Cooling Unit | Per event |

## 7. Pricing Model

Each product variant stores:

| Field | Description |
|-------|-------------|
| `unit_price` | Price per single bottle/can/keg/bag (NPR) |
| `case_size` | Number of units in a case (nullable — not all products have cases) |
| `case_price` | Price per case, typically discounted vs unit_price x case_size (nullable) |
| `mrp` | Maximum retail price for reference/display |
| `discount_type` | `percentage`, `flat`, or `none` |
| `discount_value` | Discount amount (percentage or flat NPR) |
| `discount_valid_from` | Start date of discount |
| `discount_valid_until` | End date of discount |

**Rules:**
- Not all products have case pricing (e.g., draught kegs, ice, equipment are unit-only)
- Discounts can be per-variant or event-wide promotions
- All prices managed via admin portal — never hardcoded
- Equipment has rental pricing (per event, no case concept)

## 8. Customer App (Flutter)

### Screens

1. **Auth** — Phone/email login via Supabase Auth
2. **Home** — Browse categories, search bar, filter by origin (Local/Imported), featured/discounted items
3. **Category View** — Subcategory listing with product counts
4. **Product List** — Products in a subcategory, filterable by origin, sortable by price
5. **Product Detail** — Brand info, image, available sizes, unit/case pricing, current discounts, add to cart
6. **Cart** — Line items with quantity (unit or case), running total, remove/edit items
7. **Plan My Event** — Input: guest count + event type → Output: suggested beverage quantities with estimated cost, one-tap add to cart
8. **Checkout** — Event date, delivery address, contact info, special instructions, order summary
9. **Order History** — Current and past orders with status tracking
10. **Profile** — User info, saved addresses

### Key Flows

- **Browse & Order:** Home → Category → Product List → Product Detail → Add to Cart → Cart → Checkout
- **Plan & Order:** Home → Plan My Event → Review Suggestions → Add to Cart → Checkout

## 9. Admin Portal (Web)

### Modules

1. **Auth** — Admin login (email/password via Supabase)
2. **Dashboard** — Order count, revenue summary, popular products
3. **Category Management** — CRUD categories and subcategories
4. **Product Management** — CRUD products with brand, origin, description, image upload
5. **Variant & Pricing** — CRUD variants per product (size, unit_price, case_size, case_price, mrp)
6. **Discount Management** — Create/edit discount campaigns, set validity periods, assign to variants
7. **Order Management** — View orders, update status (pending → confirmed → dispatched → delivered)
8. **Equipment Inventory** — Track draught equipment availability and rental status

## 10. Database Schema (Supabase / PostgreSQL)

### Core Tables

```sql
-- Categories: Hard Drinks, Soft Drinks, Mixers & Add-ons, Equipment
categories (
  id UUID PK,
  name TEXT NOT NULL,
  slug TEXT UNIQUE,
  sort_order INT,
  image_url TEXT,
  created_at TIMESTAMPTZ
)

-- Subcategories: Whiskey, Vodka, Beer, etc.
subcategories (
  id UUID PK,
  category_id UUID FK → categories,
  name TEXT NOT NULL,
  slug TEXT UNIQUE,
  sort_order INT,
  image_url TEXT,
  created_at TIMESTAMPTZ
)

-- Products: individual brands
products (
  id UUID PK,
  subcategory_id UUID FK → subcategories,
  name TEXT NOT NULL,
  origin TEXT CHECK (origin IN ('local', 'imported')),
  description TEXT,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  tags TEXT[],
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

-- Variants: size + pricing for each product
variants (
  id UUID PK,
  product_id UUID FK → products,
  size TEXT NOT NULL,           -- e.g., '750ml', '20L Keg', 'Per event'
  unit_price DECIMAL NOT NULL,
  case_size INT,                -- nullable
  case_price DECIMAL,           -- nullable
  mrp DECIMAL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

-- Discounts: per-variant or promotional
discounts (
  id UUID PK,
  variant_id UUID FK → variants (nullable for event-wide),
  type TEXT CHECK (type IN ('percentage', 'flat')),
  value DECIMAL NOT NULL,
  valid_from TIMESTAMPTZ,
  valid_until TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ
)

-- Users
users (
  id UUID PK (Supabase Auth),
  full_name TEXT,
  phone TEXT,
  email TEXT,
  role TEXT CHECK (role IN ('customer', 'admin')) DEFAULT 'customer',
  created_at TIMESTAMPTZ
)

-- Orders
orders (
  id UUID PK,
  user_id UUID FK → users,
  event_type TEXT,              -- wedding, birthday, corporate, etc.
  event_date DATE,
  guest_count INT,
  delivery_address TEXT,
  contact_phone TEXT,
  special_instructions TEXT,
  status TEXT CHECK (status IN ('pending', 'confirmed', 'dispatched', 'delivered', 'cancelled')),
  total_amount DECIMAL,
  discount_amount DECIMAL DEFAULT 0,
  final_amount DECIMAL,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)

-- Order Items
order_items (
  id UUID PK,
  order_id UUID FK → orders,
  variant_id UUID FK → variants,
  quantity INT NOT NULL,
  unit_type TEXT CHECK (unit_type IN ('unit', 'case')),
  unit_price DECIMAL NOT NULL,
  total_price DECIMAL NOT NULL,
  created_at TIMESTAMPTZ
)
```

## 11. Plan My Event Calculator

**Inputs:** Guest count, event type, duration (hours)

**Logic (configurable via admin):**
- Estimated consumption per guest per hour by category
- E.g., ~2 beers/person, ~0.3 bottles whiskey per 4 guests for a wedding
- Suggest a balanced mix across hard drinks, soft drinks, and mixers
- Output: recommended items with quantities, one-tap add all to cart
- Estimates are guidelines — customer can adjust before adding to cart

## 12. Out of Scope (V1)

- Bartending service
- Payment gateway integration (orders confirmed manually for now)
- Real-time delivery tracking
- Multi-vendor/marketplace model
- Loyalty/rewards program
- Inventory stock tracking (admin manages availability via is_active flags)

## 13. Future Considerations

- Online payment (eSewa, Khalti, bank transfer)
- Bartending service add-on
- Inventory management with stock counts
- Push notifications for order updates
- Rating/review system
- Referral discounts
