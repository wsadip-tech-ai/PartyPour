-- Backfill emails from auth.users into profiles where profiles.email is NULL
-- auth.users is the source of truth for email addresses

UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE p.id = u.id
  AND (p.email IS NULL OR p.email = '')
  AND u.email IS NOT NULL
  AND u.email != '';
