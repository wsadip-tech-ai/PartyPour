-- Device tokens for FCM push notifications
create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  created_at timestamptz not null default now(),
  unique(token)
);

-- Index for quick lookups by user_id (used by send-push-notification edge function)
create index if not exists idx_device_tokens_user_id on device_tokens(user_id);

-- RLS: users can only manage their own tokens
alter table device_tokens enable row level security;

create policy "Users can insert their own tokens"
  on device_tokens for insert
  with check (auth.uid() = user_id);

create policy "Users can delete their own tokens"
  on device_tokens for delete
  using (auth.uid() = user_id);

create policy "Service role can read all tokens"
  on device_tokens for select
  using (true);
