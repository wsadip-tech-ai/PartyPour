-- 002_rls_policies.sql
-- Row Level Security for RaksiChaiyo

-- Enable RLS on all tables
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE discounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Helper: check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Categories: everyone reads, admin writes
CREATE POLICY "categories_read" ON categories FOR SELECT USING (true);
CREATE POLICY "categories_admin_insert" ON categories FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "categories_admin_update" ON categories FOR UPDATE USING (is_admin());
CREATE POLICY "categories_admin_delete" ON categories FOR DELETE USING (is_admin());

-- Subcategories: everyone reads, admin writes
CREATE POLICY "subcategories_read" ON subcategories FOR SELECT USING (true);
CREATE POLICY "subcategories_admin_insert" ON subcategories FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "subcategories_admin_update" ON subcategories FOR UPDATE USING (is_admin());
CREATE POLICY "subcategories_admin_delete" ON subcategories FOR DELETE USING (is_admin());

-- Products: everyone reads active, admin reads all + writes
CREATE POLICY "products_read" ON products FOR SELECT USING (is_active = true OR is_admin());
CREATE POLICY "products_admin_insert" ON products FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "products_admin_update" ON products FOR UPDATE USING (is_admin());
CREATE POLICY "products_admin_delete" ON products FOR DELETE USING (is_admin());

-- Variants: everyone reads active, admin reads all + writes
CREATE POLICY "variants_read" ON variants FOR SELECT USING (is_active = true OR is_admin());
CREATE POLICY "variants_admin_insert" ON variants FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "variants_admin_update" ON variants FOR UPDATE USING (is_admin());
CREATE POLICY "variants_admin_delete" ON variants FOR DELETE USING (is_admin());

-- Discounts: everyone reads active+valid, admin reads all + writes
CREATE POLICY "discounts_read" ON discounts FOR SELECT USING (
  (is_active = true AND valid_from <= now() AND valid_until > now()) OR is_admin()
);
CREATE POLICY "discounts_admin_insert" ON discounts FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "discounts_admin_update" ON discounts FOR UPDATE USING (is_admin());
CREATE POLICY "discounts_admin_delete" ON discounts FOR DELETE USING (is_admin());

-- Profiles: users read own, admin reads all
CREATE POLICY "profiles_read_own" ON profiles FOR SELECT USING (id = auth.uid() OR is_admin());
CREATE POLICY "profiles_update_own" ON profiles FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid() AND role = 'customer');

-- Orders: users see own, admin sees all
CREATE POLICY "orders_read" ON orders FOR SELECT USING (user_id = auth.uid() OR is_admin());
CREATE POLICY "orders_insert" ON orders FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "orders_update_admin" ON orders FOR UPDATE USING (is_admin());

-- Order Items: users see own order's items, admin sees all
CREATE POLICY "order_items_read" ON order_items FOR SELECT USING (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid()) OR is_admin()
);
CREATE POLICY "order_items_insert" ON order_items FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM orders WHERE orders.id = order_items.order_id AND orders.user_id = auth.uid())
);
