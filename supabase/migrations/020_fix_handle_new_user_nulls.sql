-- Fix handle_new_user to store NULL instead of empty strings
-- so that admin portal fallback text ('Unknown', 'No email') works correctly

CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    NULLIF(COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      ''
    ), ''),
    NULLIF(COALESCE(NEW.email, ''), ''),
    'customer'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION
  WHEN others THEN
    RAISE LOG 'handle_new_user failed for %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Also fix existing empty-string rows to NULL
UPDATE profiles SET full_name = NULL WHERE full_name = '';
UPDATE profiles SET email = NULL WHERE email = '';
UPDATE profiles SET phone = NULL WHERE phone = '';
