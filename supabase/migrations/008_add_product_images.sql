-- 008_add_product_images.sql
-- Add product images from Nepal retailer CDNs

-- WHISKEY
UPDATE products SET image_url = 'https://fatafatsewa.com/storage/media/6916/Old-Durbar-750-Ml-Price-in-Nepal.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000004'; -- Old Durbar
UPDATE products SET image_url = 'https://static-01.daraz.com.np/p/f87a772e491ede6af49cd5d50305c011.jpg' WHERE name = 'Old Durbar' AND image_url IS NULL;

-- Khukuri (whiskey in our catalog)
UPDATE products SET image_url = 'https://static-01.daraz.com.np/p/24b495feaf0417bbb5f598735f2732aa.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000001'; -- Khukuri

-- VODKA
UPDATE products SET image_url = 'https://liquorsnepal.com/wp-content/uploads/2020/08/ABSOLUT_VODKA_750ML__16867.1553621218.1280.1280.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000009'; -- Absolut

-- BEER
UPDATE products SET image_url = 'https://static-01.daraz.com.np/p/317d606f529f709f64dccd737fe9334c.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000023'; -- Tuborg
UPDATE products SET image_url = 'https://static-01.daraz.com.np/p/271a07eb83d24daf457777d4af796443.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000022'; -- Gorkha
UPDATE products SET image_url = 'https://static-01.daraz.com.np/p/9ab9aa37e95a9eb137307a32fc0a8e0c.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000024'; -- Nepal Ice

-- SOFT DRINKS
UPDATE products SET image_url = 'https://static-01.daraz.com.np/p/97a65b5a384ea8605d80f0569f797840.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000029'; -- Coca-Cola

-- ENERGY DRINKS
UPDATE products SET image_url = 'https://onlineliquornepal.com/wp-content/uploads/2021/01/Red-Bull-Original.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000038'; -- Red Bull

-- SHOTS
UPDATE products SET image_url = 'https://static-01.daraz.com.np/p/fd0523075a636615f57705b38f246cee.png' WHERE id = 'c1000000-0000-0000-0000-000000000055'; -- Jagermeister

-- RUM
UPDATE products SET image_url = 'https://onlineliquornepal.com/wp-content/uploads/2020/12/New-Pack-Khukri-Rum-in-Nepal.jpg' WHERE id = 'c1000000-0000-0000-0000-000000000011'; -- Khukuri Rum
