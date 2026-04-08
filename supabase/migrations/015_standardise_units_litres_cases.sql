-- 015_standardise_units_litres_cases.sql
-- Standardise all product variants:
--   Spirits/wine/beverages → single variant per product in litres (1L)
--   Beer → single variant per product as case
--   Soda/Ice cream → keep litre-based sizes

-- ============================================
-- STEP 0: Clear test order data that references old variants
-- (pre-launch only — no real orders exist yet)
-- ============================================

DELETE FROM order_items;
DELETE FROM orders;

-- ============================================
-- STEP 1: Delete all 375ml, 330ml, 650ml, 700ml, 500ml variants
-- (keeping only the largest/primary variant per product)
-- ============================================

-- Delete small spirit/wine variants (375ml)
DELETE FROM variants WHERE size = '375ml';

-- Delete small beer variants (330ml)
DELETE FROM variants WHERE size = '330ml';

-- Delete 700ml variants (brandy — will be updated to 1L)
DELETE FROM variants WHERE size = '700ml';

-- ============================================
-- STEP 2: Update remaining spirit/wine/beverage 750ml → 1L
-- Scale price: 1L price = 750ml price × 1.33 (rounded)
-- ============================================

UPDATE variants
SET size = '1L',
    unit_price = ROUND(unit_price * 1.33, 0),
    mrp = ROUND(mrp * 1.33, 0),
    case_price = CASE WHEN case_price IS NOT NULL THEN ROUND(case_price * 1.33, 0) ELSE NULL END
WHERE size = '750ml';

-- ============================================
-- STEP 3: Update beer 650ml → 'Case' format
-- Beer should show as case, price = case_price
-- ============================================

UPDATE variants
SET size = 'Case of ' || COALESCE(case_size, 12),
    unit_price = COALESCE(case_price, unit_price * COALESCE(case_size, 12)),
    mrp = COALESCE(case_price, mrp * COALESCE(case_size, 12))
WHERE product_id IN (
    SELECT p.id FROM products p
    JOIN subcategories s ON p.subcategory_id = s.id
    WHERE s.slug = 'beer-bottle-can'
) AND size = '650ml';

-- ============================================
-- STEP 4: Fix soda — Club Soda 750ml → 1L, Tonic Water 500ml → 1L
-- ============================================

UPDATE variants SET size = '1L', unit_price = ROUND(unit_price * 1.33, 0), mrp = ROUND(mrp * 1.33, 0)
WHERE product_id = 'c1000000-0000-0000-0000-000000000074' AND size = '750ml';

UPDATE variants SET size = '1L', unit_price = ROUND(unit_price * 2, 0), mrp = ROUND(mrp * 2, 0)
WHERE product_id = 'c1000000-0000-0000-0000-000000000075' AND size = '500ml';

-- ============================================
-- STEP 5: Fix soda multi-sizes — keep only 1.5L, delete 2.25L
-- ============================================

DELETE FROM variants WHERE size = '2.25L' AND product_id IN (
    'c1000000-0000-0000-0000-000000000070',
    'c1000000-0000-0000-0000-000000000071'
);

-- Rename 1.5L sodas to 1L for consistency
UPDATE variants SET size = '1L', unit_price = ROUND(unit_price / 1.5, 0), mrp = ROUND(mrp / 1.5, 0),
    case_price = CASE WHEN case_price IS NOT NULL THEN ROUND(case_price / 1.5, 0) ELSE NULL END
WHERE size = '1.5L';
