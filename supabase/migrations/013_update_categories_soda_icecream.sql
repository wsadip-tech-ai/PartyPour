-- 013_update_categories_soda_icecream.sql
-- Remove cocktail-mixers from estimation, add soda and ice-cream

-- Deactivate cocktail-mixers estimation rule
UPDATE estimation_rules SET is_active = false WHERE subcategory_slug = 'cocktail-mixers';

-- Add soda subcategory and estimation rule
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000018', 'a1000000-0000-0000-0000-000000000002', 'Soda', 'soda', 5);

INSERT INTO estimation_rules (subcategory_slug, label, icon_name, drinks_per_guest, servings_per_bottle, event_multipliers, children_factor, sort_order) VALUES
  ('soda', 'Soda', 'local_cafe', 1.5, 4, '{"wedding":1.0,"birthday":1.2,"corporate":1.0,"house_party":1.2,"anniversary":1.0,"other":1.0}', 1.0, 15);

-- Add ice-cream subcategory and estimation rule
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000019', 'a1000000-0000-0000-0000-000000000002', 'Ice Cream', 'ice-cream', 6);

INSERT INTO estimation_rules (subcategory_slug, label, icon_name, drinks_per_guest, servings_per_bottle, event_multipliers, children_factor, sort_order) VALUES
  ('ice-cream', 'Ice Cream', 'ac_unit', 0.5, 10, '{"wedding":1.0,"birthday":1.5,"corporate":0.6,"house_party":1.2,"anniversary":1.0,"other":1.0}', 1.5, 16);
