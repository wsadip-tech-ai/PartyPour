-- 003_seed_data.sql
-- RaksiChaiyo initial catalog: Nepal beverage market

-- Categories
INSERT INTO categories (id, name, slug, sort_order) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Hard Drinks', 'hard-drinks', 1),
  ('a1000000-0000-0000-0000-000000000002', 'Soft Drinks', 'soft-drinks', 2),
  ('a1000000-0000-0000-0000-000000000003', 'Mixers & Add-ons', 'mixers-add-ons', 3),
  ('a1000000-0000-0000-0000-000000000004', 'Equipment (Rental)', 'equipment-rental', 4);

-- Subcategories - Hard Drinks
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Whiskey', 'whiskey', 1),
  ('b1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001', 'Vodka', 'vodka', 2),
  ('b1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001', 'Rum', 'rum', 3),
  ('b1000000-0000-0000-0000-000000000004', 'a1000000-0000-0000-0000-000000000001', 'Wine', 'wine', 4),
  ('b1000000-0000-0000-0000-000000000005', 'a1000000-0000-0000-0000-000000000001', 'Beer (Bottle/Can)', 'beer-bottle-can', 5),
  ('b1000000-0000-0000-0000-000000000006', 'a1000000-0000-0000-0000-000000000001', 'Beer (Draught)', 'beer-draught', 6),
  ('b1000000-0000-0000-0000-000000000007', 'a1000000-0000-0000-0000-000000000001', 'Gin', 'gin', 7);

-- Subcategories - Soft Drinks
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000008', 'a1000000-0000-0000-0000-000000000002', 'Carbonated', 'carbonated', 1),
  ('b1000000-0000-0000-0000-000000000009', 'a1000000-0000-0000-0000-000000000002', 'Juice', 'juice', 2),
  ('b1000000-0000-0000-0000-000000000010', 'a1000000-0000-0000-0000-000000000002', 'Water', 'water', 3),
  ('b1000000-0000-0000-0000-000000000011', 'a1000000-0000-0000-0000-000000000002', 'Energy Drinks', 'energy-drinks', 4);

-- Subcategories - Mixers & Add-ons
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000012', 'a1000000-0000-0000-0000-000000000003', 'Mixers', 'mixers', 1),
  ('b1000000-0000-0000-0000-000000000013', 'a1000000-0000-0000-0000-000000000003', 'Ice & Garnish', 'ice-garnish', 2);

-- Subcategories - Equipment
INSERT INTO subcategories (id, category_id, name, slug, sort_order) VALUES
  ('b1000000-0000-0000-0000-000000000014', 'a1000000-0000-0000-0000-000000000004', 'Draught Beer Setup', 'draught-beer-setup', 1);

-- WHISKEY
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Khukuri', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000001', '750ml', 550.00, 12, 6000.00, 580.00),
  ('c1000000-0000-0000-0000-000000000001', '375ml', 290.00, 24, 6400.00, 310.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Ruslan', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000002', '750ml', 520.00, 12, 5700.00, 550.00),
  ('c1000000-0000-0000-0000-000000000002', '375ml', 270.00, 24, 6000.00, 290.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Mt. Everest', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000003', '750ml', 480.00, 12, 5300.00, 510.00),
  ('c1000000-0000-0000-0000-000000000003', '375ml', 250.00, 24, 5500.00, 270.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'Old Durbar', 'local', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000004', '750ml', 700.00, 12, 7800.00, 750.00),
  ('c1000000-0000-0000-0000-000000000004', '375ml', 370.00, 24, 8200.00, 400.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000001', 'Johnnie Walker Red Label', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000005', '750ml', 3200.00, 12, 36000.00, 3400.00),
  ('c1000000-0000-0000-0000-000000000005', '1L', 4200.00, 12, 48000.00, 4500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000006', 'b1000000-0000-0000-0000-000000000001', 'Johnnie Walker Black Label', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000006', '750ml', 5500.00, 12, 62000.00, 5800.00),
  ('c1000000-0000-0000-0000-000000000006', '1L', 7200.00, 12, 82000.00, 7500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000001', '100 Pipers', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000007', '750ml', 2800.00, 12, 31000.00, 3000.00);

-- VODKA
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000008', 'b1000000-0000-0000-0000-000000000002', 'Ruslan Vodka', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000008', '750ml', 500.00, 12, 5500.00, 530.00),
  ('c1000000-0000-0000-0000-000000000008', '375ml', 260.00, 24, 5800.00, 280.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000009', 'b1000000-0000-0000-0000-000000000002', 'Absolut', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000009', '750ml', 3500.00, 12, 39000.00, 3700.00),
  ('c1000000-0000-0000-0000-000000000009', '1L', 4500.00, 12, 50000.00, 4800.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000010', 'b1000000-0000-0000-0000-000000000002', 'Smirnoff', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000010', '750ml', 2500.00, 12, 28000.00, 2700.00);

-- RUM
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000011', 'b1000000-0000-0000-0000-000000000003', 'Khukuri Rum', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000011', '750ml', 500.00, 12, 5500.00, 530.00),
  ('c1000000-0000-0000-0000-000000000011', '375ml', 260.00, 24, 5800.00, 280.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000012', 'b1000000-0000-0000-0000-000000000003', 'Old Monk', 'imported', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000012', '750ml', 1200.00, 12, 13000.00, 1300.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000013', 'b1000000-0000-0000-0000-000000000003', 'Bacardi', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000013', '750ml', 2800.00, 12, 31000.00, 3000.00);

-- WINE
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000014', 'b1000000-0000-0000-0000-000000000004', 'Hinwa Red', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000014', '750ml', 800.00, 6, 4500.00, 850.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000015', 'b1000000-0000-0000-0000-000000000004', 'Hinwa White', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000015', '750ml', 800.00, 6, 4500.00, 850.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000016', 'b1000000-0000-0000-0000-000000000004', 'Jacob''s Creek Red', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000016', '750ml', 2200.00, 6, 12000.00, 2400.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000017', 'b1000000-0000-0000-0000-000000000004', 'Jacob''s Creek White', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000017', '750ml', 2200.00, 6, 12000.00, 2400.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000018', 'b1000000-0000-0000-0000-000000000004', 'Carlo Rossi Red', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000018', '750ml', 1500.00, 6, 8200.00, 1600.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000019', 'b1000000-0000-0000-0000-000000000004', 'Carlo Rossi White', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000019', '750ml', 1500.00, 6, 8200.00, 1600.00);

-- GIN
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000020', 'b1000000-0000-0000-0000-000000000007', 'Sherpa Gin', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000020', '750ml', 600.00, 12, 6600.00, 650.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000021', 'b1000000-0000-0000-0000-000000000007', 'Gordon''s', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000021', '750ml', 2600.00, 12, 29000.00, 2800.00);

-- BEER (BOTTLE/CAN)
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000022', 'b1000000-0000-0000-0000-000000000005', 'Gorkha', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000022', '650ml', 400.00, 12, 4400.00, 430.00),
  ('c1000000-0000-0000-0000-000000000022', '330ml', 220.00, 24, 4800.00, 240.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000023', 'b1000000-0000-0000-0000-000000000005', 'Tuborg', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000023', '650ml', 380.00, 12, 4200.00, 410.00),
  ('c1000000-0000-0000-0000-000000000023', '330ml', 210.00, 24, 4600.00, 230.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000024', 'b1000000-0000-0000-0000-000000000005', 'Nepal Ice', 'local', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000024', '650ml', 370.00, 12, 4100.00, 400.00),
  ('c1000000-0000-0000-0000-000000000024', '330ml', 200.00, 24, 4400.00, 220.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000025', 'b1000000-0000-0000-0000-000000000005', 'Carlsberg', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000025', '650ml', 400.00, 12, 4400.00, 430.00),
  ('c1000000-0000-0000-0000-000000000025', '330ml', 220.00, 24, 4800.00, 240.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000026', 'b1000000-0000-0000-0000-000000000005', 'Budweiser', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000026', '330ml', 350.00, 24, 7800.00, 380.00);

-- BEER (DRAUGHT)
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000027', 'b1000000-0000-0000-0000-000000000006', 'Gorkha Draught', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000027', '20L Keg', 8000.00, 8500.00),
  ('c1000000-0000-0000-0000-000000000027', '50L Keg', 18000.00, 19000.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000028', 'b1000000-0000-0000-0000-000000000006', 'Tuborg Draught', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000028', '20L Keg', 7500.00, 8000.00),
  ('c1000000-0000-0000-0000-000000000028', '50L Keg', 17000.00, 18000.00);

-- CARBONATED
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000029', 'b1000000-0000-0000-0000-000000000008', 'Coca-Cola', 'imported', '{popular}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000029', '2.25L', 180.00, 6, 1000.00, 200.00),
  ('c1000000-0000-0000-0000-000000000029', '500ml', 60.00, 24, 1300.00, 70.00),
  ('c1000000-0000-0000-0000-000000000029', '300ml', 40.00, 24, 880.00, 45.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000030', 'b1000000-0000-0000-0000-000000000008', 'Fanta', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000030', '2.25L', 180.00, 6, 1000.00, 200.00),
  ('c1000000-0000-0000-0000-000000000030', '500ml', 60.00, 24, 1300.00, 70.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000031', 'b1000000-0000-0000-0000-000000000008', 'Sprite', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000031', '2.25L', 180.00, 6, 1000.00, 200.00),
  ('c1000000-0000-0000-0000-000000000031', '500ml', 60.00, 24, 1300.00, 70.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000032', 'b1000000-0000-0000-0000-000000000008', 'Real Gold Soda', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000032', '300ml', 30.00, 24, 650.00, 35.00);

-- JUICE
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000033', 'b1000000-0000-0000-0000-000000000009', 'Real', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000033', '1L', 250.00, 12, 2800.00, 280.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000034', 'b1000000-0000-0000-0000-000000000009', 'Frooti', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000034', '1L', 150.00, 12, 1650.00, 170.00),
  ('c1000000-0000-0000-0000-000000000034', '200ml', 25.00, 36, 800.00, 30.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000035', 'b1000000-0000-0000-0000-000000000009', 'Local Fresh Juice', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000035', '1L', 200.00, 220.00);

-- WATER
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000036', 'b1000000-0000-0000-0000-000000000010', 'Aqua Nepal', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000036', '20L', 150.00, NULL, NULL, 170.00),
  ('c1000000-0000-0000-0000-000000000036', '1L', 30.00, 12, 320.00, 35.00),
  ('c1000000-0000-0000-0000-000000000036', '500ml', 20.00, 24, 420.00, 25.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000037', 'b1000000-0000-0000-0000-000000000010', 'Himalayan', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000037', '1L', 35.00, 12, 380.00, 40.00),
  ('c1000000-0000-0000-0000-000000000037', '500ml', 25.00, 24, 520.00, 30.00);

-- ENERGY DRINKS
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000038', 'b1000000-0000-0000-0000-000000000011', 'Red Bull', 'imported', '{premium}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000038', '250ml', 250.00, 24, 5500.00, 275.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000039', 'b1000000-0000-0000-0000-000000000011', 'Sting', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000039', '250ml', 100.00, 24, 2200.00, 120.00);

-- MIXERS
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000040', 'b1000000-0000-0000-0000-000000000012', 'Tonic Water', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000040', '500ml', 120.00, 12, 1300.00, 140.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000041', 'b1000000-0000-0000-0000-000000000012', 'Soda Water', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000041', '500ml', 40.00, 24, 880.00, 45.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000042', 'b1000000-0000-0000-0000-000000000012', 'Ginger Ale', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, case_size, case_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000042', '330ml', 150.00, 12, 1650.00, 170.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000043', 'b1000000-0000-0000-0000-000000000012', 'Lime Cordial', 'imported', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000043', '750ml', 350.00, 400.00);

-- ICE & GARNISH
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000044', 'b1000000-0000-0000-0000-000000000013', 'Ice (Cubed)', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000044', '5kg bag', 150.00, 170.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000045', 'b1000000-0000-0000-0000-000000000013', 'Lemon/Lime', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000045', 'Per kg', 200.00, 220.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000046', 'b1000000-0000-0000-0000-000000000013', 'Mint', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000046', 'Per bunch', 50.00, 60.00);

-- EQUIPMENT (RENTAL)
INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000047', 'b1000000-0000-0000-0000-000000000014', 'Draught Beer Dispenser', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000047', 'Per event', 5000.00, 5500.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000048', 'b1000000-0000-0000-0000-000000000014', 'CO2 Cylinder', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000048', 'Per unit', 1500.00, 1700.00);

INSERT INTO products (id, subcategory_id, name, origin, tags) VALUES
  ('c1000000-0000-0000-0000-000000000049', 'b1000000-0000-0000-0000-000000000014', 'Draught Cooling Unit', 'local', '{}');
INSERT INTO variants (product_id, size, unit_price, mrp) VALUES
  ('c1000000-0000-0000-0000-000000000049', 'Per event', 3000.00, 3500.00);
