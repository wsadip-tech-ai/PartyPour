-- 009_create_admin_user.sql
-- Promote admin@raksichaiyo.com to admin role

UPDATE profiles SET role = 'admin' WHERE email = 'admin@raksichaiyo.com';
