-- 004_storage.sql
-- Product image storage bucket

INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true);

-- Anyone can read product images
CREATE POLICY "product_images_read" ON storage.objects
  FOR SELECT USING (bucket_id = 'product-images');

-- Only admins can upload/update/delete images
CREATE POLICY "product_images_admin_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'product-images'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "product_images_admin_update" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'product-images'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "product_images_admin_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'product-images'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );
