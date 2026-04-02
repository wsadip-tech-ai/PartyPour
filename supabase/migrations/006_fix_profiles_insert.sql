-- 006_fix_profiles_insert.sql
-- The handle_new_user trigger runs as SECURITY DEFINER so it bypasses RLS.
-- But just in case, add an explicit insert policy for the auth trigger.
-- Also ensure the profiles table allows inserts from the service role.

-- Allow users to insert their own profile (backup for trigger)
CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (id = auth.uid());
