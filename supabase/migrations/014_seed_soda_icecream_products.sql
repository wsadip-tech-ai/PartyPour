-- 014_seed_soda_icecream_products.sql
-- Add products for Soda and Ice Cream subcategories

-- ============================================
-- Soda products (subcategory_id = b1000000-0000-0000-0000-000000000018)
-- ============================================

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000070', 'b1000000-0000-0000-0000-000000000018', 'Coke (Coca-Cola)', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000070', '1.5L', 120.00, 12, 1320.00, 130.00),
  ('c1000000-0000-0000-0000-000000000070', '2.25L', 160.00, 8, 1200.00, 170.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000071', 'b1000000-0000-0000-0000-000000000018', 'Sprite', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000071', '1.5L', 120.00, 12, 1320.00, 130.00),
  ('c1000000-0000-0000-0000-000000000071', '2.25L', 160.00, 8, 1200.00, 170.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000072', 'b1000000-0000-0000-0000-000000000018', 'Fanta', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000072', '1.5L', 120.00, 12, 1320.00, 130.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000073', 'b1000000-0000-0000-0000-000000000018', 'Mountain Dew', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000073', '1.5L', 120.00, 12, 1320.00, 130.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000074', 'b1000000-0000-0000-0000-000000000018', 'Club Soda', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000074', '750ml', 40.00, 24, 900.00, 45.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000075', 'b1000000-0000-0000-0000-000000000018', 'Tonic Water', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000075', '500ml', 180.00, 24, 4000.00, 200.00);

-- ============================================
-- Ice Cream products (subcategory_id = b1000000-0000-0000-0000-000000000019)
-- ============================================

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000080', 'b1000000-0000-0000-0000-000000000019', 'Kwality Walls Vanilla Tub', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000080', '5L Tub', 1200.00, 1350.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000081', 'b1000000-0000-0000-0000-000000000019', 'Kwality Walls Chocolate Tub', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000081', '5L Tub', 1200.00, 1350.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000082', 'b1000000-0000-0000-0000-000000000019', 'Kwality Walls Strawberry Tub', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000082', '5L Tub', 1200.00, 1350.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000083', 'b1000000-0000-0000-0000-000000000019', 'BRB Mango Ice Cream', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000083', '5L Tub', 1000.00, 1150.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000084', 'b1000000-0000-0000-0000-000000000019', 'BRB Kulfi Malai', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000084', '5L Tub', 1100.00, 1250.00);
