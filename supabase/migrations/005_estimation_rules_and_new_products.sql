-- 005_estimation_rules_and_new_products.sql
-- Estimation engine + new subcategories (brandy, shots, cocktail mixers)

-- ============================================
-- Estimation Rules table
-- ============================================
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

CREATE TRIGGER trg_estimation_rules_updated_at
  BEFORE UPDATE ON estimation_rules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE estimation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "estimation_rules_read" ON estimation_rules
  FOR SELECT USING (is_active = true OR is_admin());

CREATE POLICY "estimation_rules_admin_insert" ON estimation_rules
  FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "estimation_rules_admin_update" ON estimation_rules
  FOR UPDATE USING (is_admin());

CREATE POLICY "estimation_rules_admin_delete" ON estimation_rules
  FOR DELETE USING (is_admin());

-- ============================================
-- Seed estimation rules
-- ============================================
INSERT INTO estimation_rules (subcategory_slug, label, icon_name, drinks_per_guest, servings_per_bottle, event_multipliers, children_factor, sort_order) VALUES
  ('whiskey', 'Whiskey', 'local_bar', 3.0, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 1),
  ('vodka', 'Vodka', 'local_bar', 1.5, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 2),
  ('gin', 'Gin', 'local_bar', 1.0, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 3),
  ('rum', 'Rum', 'local_bar', 1.5, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 4),
  ('brandy', 'Brandy', 'wine_bar', 0.5, 12, '{"wedding":1.0,"birthday":0.8,"corporate":0.6,"house_party":1.2,"anniversary":0.9,"other":1.0}', 0, 5),
  ('beer-bottle-can', 'Beer', 'sports_bar', 2.0, 1, '{"wedding":1.0,"birthday":1.2,"corporate":0.8,"house_party":1.5,"anniversary":0.8,"other":1.0}', 0, 6),
  ('wine', 'Wine', 'wine_bar', 1.0, 5, '{"wedding":1.2,"birthday":0.6,"corporate":1.0,"house_party":0.8,"anniversary":1.2,"other":1.0}', 0, 7),
  ('shots-specials', 'Shots/Specials', 'local_fire_department', 1.0, 16, '{"wedding":0.8,"birthday":1.2,"corporate":0.4,"house_party":1.5,"anniversary":0.6,"other":1.0}', 0, 8),
  ('energy-drinks', 'Energy Drinks', 'bolt', 0.5, 1, '{"wedding":0.8,"birthday":1.0,"corporate":0.6,"house_party":1.2,"anniversary":0.8,"other":1.0}', 0.5, 9),
  ('cocktail-mixers', 'Cocktails', 'blender', 1.0, 8, '{"wedding":1.0,"birthday":1.0,"corporate":0.8,"house_party":1.2,"anniversary":1.0,"other":1.0}', 0, 10),
  ('carbonated', 'Cold Drinks', 'local_cafe', 2.0, 4, '{"wedding":1.0,"birthday":1.2,"corporate":1.0,"house_party":1.2,"anniversary":1.0,"other":1.0}', 1.0, 11),
  ('juice', 'Juice', 'local_cafe', 1.0, 4, '{"wedding":1.0,"birthday":1.5,"corporate":1.0,"house_party":1.0,"anniversary":1.0,"other":1.0}', 1.5, 12),
  ('water', 'Water', 'water_drop', 2.0, 2, '{"wedding":1.0,"birthday":1.0,"corporate":1.0,"house_party":1.0,"anniversary":1.0,"other":1.0}', 1.0, 13),
  ('ice-garnish', 'Ice', 'ac_unit', 1.0, 10, '{"wedding":1.0,"birthday":1.0,"corporate":1.0,"house_party":1.0,"anniversary":1.0,"other":1.0}', 1.0, 14);

-- ============================================
-- New subcategories
-- ============================================
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000015', 'a1000000-0000-0000-0000-000000000001', 'Brandy', 'brandy', 8),
  ('b1000000-0000-0000-0000-000000000016', 'a1000000-0000-0000-0000-000000000001', 'Shots/Specials', 'shots-specials', 9),
  ('b1000000-0000-0000-0000-000000000017', 'a1000000-0000-0000-0000-000000000003', 'Cocktail Mixers', 'cocktail-mixers', 3);

-- ============================================
-- Brandy products
-- ============================================
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000050', 'b1000000-0000-0000-0000-000000000015', 'Sandesh Jumla Apple Brandy', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000050', '750ml', 1000.00, 12, 11000.00, 1100.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000051', 'b1000000-0000-0000-0000-000000000015', 'E&J VSOP', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000051', '1L', 4285.00, 4500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000052', 'b1000000-0000-0000-0000-000000000015', 'Bardinet Napoleon VSOP', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000052', '700ml', 3855.00, 4100.00),
  ('c1000000-0000-0000-0000-000000000052', '1L', 5290.00, 5500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000053', 'b1000000-0000-0000-0000-000000000015', 'St. Remy Authentic VSOP', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000053', '1L', 5595.00, 5800.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000054', 'b1000000-0000-0000-0000-000000000015', 'Martell VS', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000054', '1L', 9415.00, 9800.00);

-- ============================================
-- Shots/Specials products
-- ============================================
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000055', 'b1000000-0000-0000-0000-000000000016', 'Jagermeister', 'imported', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000055', '750ml', 3500.00, 12, 39000.00, 3700.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000056', 'b1000000-0000-0000-0000-000000000016', 'Tequila Jose Cuervo Gold', 'imported', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000056', '750ml', 4200.00, 12, 47000.00, 4500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000057', 'b1000000-0000-0000-0000-000000000016', 'Aila (Newari Rice Spirit)', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000057', '750ml', 400.00, 450.00);

-- ============================================
-- Cocktail Mixers products
-- ============================================
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000058', 'b1000000-0000-0000-0000-000000000017', 'Cranberry Juice (mixer)', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000058', '1L', 350.00, 12, 3800.00, 400.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000059', 'b1000000-0000-0000-0000-000000000017', 'Orange Juice (mixer)', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000059', '1L', 300.00, 12, 3300.00, 350.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000060', 'b1000000-0000-0000-0000-000000000017', 'Grenadine Syrup', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000060', '750ml', 500.00, 550.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000061', 'b1000000-0000-0000-0000-000000000017', 'Triple Sec', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000061', '750ml', 1800.00, 2000.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000062', 'b1000000-0000-0000-0000-000000000017', 'Simple Syrup', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000062', '500ml', 200.00, 250.00);
