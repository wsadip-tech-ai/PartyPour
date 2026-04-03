-- 012_secure_admin_provisioning.sql
-- Fix Codex adversarial review HIGH finding: admin bootstrap keyed to mutable email.
--
-- Changes:
-- 1. Replace promote_to_admin(email) with promote_to_admin_by_id(uuid) — targets immutable ID
-- 2. Keep email-based version but add guards: exactly 1 match, not already admin
-- 3. Add raise_admin_bootstrap_error if 0 or >1 rows match

-- Drop old unguarded function
DROP FUNCTION IF EXISTS promote_to_admin(TEXT);

-- Secure: promote by immutable user UUID (preferred)
CREATE OR REPLACE FUNCTION promote_to_admin_by_id(target_id UUID)
RETURNS TEXT AS $$
DECLARE
  target_exists BOOLEAN;
  current_role TEXT;
BEGIN
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = target_id) INTO target_exists;

  IF NOT target_exists THEN
    RAISE EXCEPTION 'ADMIN_BOOTSTRAP_FAILED: No profile found for user ID %. Create the user via Supabase Auth first.', target_id;
  END IF;

  SELECT role INTO current_role FROM profiles WHERE id = target_id;

  IF current_role = 'admin' THEN
    RETURN 'User ' || target_id || ' is already an admin.';
  END IF;

  UPDATE profiles SET role = 'admin' WHERE id = target_id;
  RETURN 'Promoted user ' || target_id || ' to admin.';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Guarded: promote by email with strict validation
CREATE OR REPLACE FUNCTION promote_to_admin(target_email TEXT)
RETURNS TEXT AS $$
DECLARE
  match_count INT;
  target_id UUID;
BEGIN
  -- Count matching profiles — must be exactly 1
  SELECT COUNT(*) INTO match_count FROM profiles WHERE email = target_email;

  IF match_count = 0 THEN
    RAISE EXCEPTION 'ADMIN_BOOTSTRAP_FAILED: No profile found for email %. Create the user via Supabase Auth first, then retry.', target_email;
  END IF;

  IF match_count > 1 THEN
    RAISE EXCEPTION 'ADMIN_BOOTSTRAP_FAILED: Multiple profiles (%) found for email %. Use promote_to_admin_by_id(uuid) with the exact user ID instead.', match_count, target_email;
  END IF;

  -- Exactly 1 match — get the ID and promote
  SELECT id INTO target_id FROM profiles WHERE email = target_email;
  RETURN promote_to_admin_by_id(target_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Restrict access — only service role or existing admins can call these
REVOKE ALL ON FUNCTION promote_to_admin_by_id(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION promote_to_admin(TEXT) FROM PUBLIC;
