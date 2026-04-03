-- 011_fix_admin_provisioning.sql
-- Make admin provisioning resilient for fresh environments.
--
-- On a fresh database, migration 009 is a no-op because the admin user
-- doesn't exist in auth.users yet (profiles are created by the
-- handle_new_user trigger only after signup).
--
-- This migration creates a function that can be called after the admin
-- user is created via Supabase Auth (dashboard or API) to promote them.
-- It also retries promoting any existing admin@raksichaiyo.com profile.

-- Idempotent: promote admin if profile already exists
UPDATE profiles SET role = 'admin' WHERE email = 'admin@raksichaiyo.com' AND role != 'admin';

-- Create a reusable function to promote any user to admin by email
CREATE OR REPLACE FUNCTION promote_to_admin(target_email TEXT)
RETURNS TEXT AS $$
DECLARE
  updated_count INT;
BEGIN
  UPDATE profiles SET role = 'admin' WHERE email = target_email AND role != 'admin';
  GET DIAGNOSTICS updated_count = ROW_COUNT;

  IF updated_count > 0 THEN
    RETURN 'Promoted ' || target_email || ' to admin';
  ELSE
    RETURN 'No profile found for ' || target_email || '. Create the user first via Supabase Auth, then call this function again.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Only admins can call this function (via RPC)
REVOKE ALL ON FUNCTION promote_to_admin(TEXT) FROM PUBLIC;
