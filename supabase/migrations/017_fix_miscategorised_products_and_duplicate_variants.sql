-- 017_fix_miscategorised_products_and_duplicate_variants.sql
-- Fix: Khukuri and Ruslan are miscategorised under Whiskey.
--   "Khukuri Rum" already exists under Rum, "Ruslan Vodka" under Vodka.
--   Delete the duplicates from Whiskey.
-- Fix: Deduplicate any variants with the same (product_id, size).

-- ============================================
-- STEP 1: Remove miscategorised products from Whiskey
-- Khukuri (c1-001) is a rum — duplicate of Khukuri Rum (c1-011)
-- Ruslan (c1-002) is a vodka — duplicate of Ruslan Vodka (c1-008)
-- ============================================

-- Delete order_items referencing these variants first
DELETE FROM order_items WHERE variant_id IN (
  SELECT id FROM variants WHERE product_id IN (
    'c1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000002'
  )
);

-- Delete their variants (FK constraint)
DELETE FROM variants WHERE product_id IN (
  'c1000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000002'
);

-- Delete the misplaced products
DELETE FROM products WHERE id IN (
  'c1000000-0000-0000-0000-000000000001',
  'c1000000-0000-0000-0000-000000000002'
);

-- ============================================
-- STEP 2: Deduplicate variants with same size per product
-- Keep the variant with the higher unit_price (more likely the correct/updated one)
-- ============================================

-- First, migrate order_items from duplicate variants to the kept variant
-- (reassign to the variant with highest price per product+size group)
UPDATE order_items SET variant_id = keeper.id
FROM (
  SELECT DISTINCT ON (v.product_id, v.size) v.id, v.product_id, v.size
  FROM variants v
  ORDER BY v.product_id, v.size, v.unit_price DESC, v.created_at ASC
) keeper
WHERE order_items.variant_id IN (
  SELECT v2.id FROM variants v2
  WHERE v2.product_id = keeper.product_id AND v2.size = keeper.size AND v2.id != keeper.id
);

-- Now delete duplicate variants (keep highest price, then earliest created)
DELETE FROM variants
WHERE id IN (
  SELECT v.id
  FROM variants v
  INNER JOIN (
    SELECT product_id, size, MAX(unit_price) AS max_price
    FROM variants
    GROUP BY product_id, size
    HAVING COUNT(*) > 1
  ) dup ON v.product_id = dup.product_id AND v.size = dup.size AND v.unit_price < dup.max_price
);

-- If both duplicates have exact same price, keep the one with earliest created_at
DELETE FROM order_items WHERE variant_id NOT IN (SELECT id FROM variants);

DELETE FROM variants
WHERE id NOT IN (
  SELECT DISTINCT ON (product_id, size) id
  FROM variants
  ORDER BY product_id, size, created_at ASC
);
