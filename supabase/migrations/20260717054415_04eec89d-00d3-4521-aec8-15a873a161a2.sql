
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  recipient_id uuid references auth.users(id) on delete cascade,
  body text not null check (length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);
grant select, insert, update, delete on public.messages to authenticated;
grant all on public.messages to service_role;
alter table public.messages enable row level security;

create index on public.messages(created_at desc);
create index on public.messages(recipient_id);
create index on public.messages(sender_id);

-- Team room: anyone signed in can read
create policy "Anyone signed-in reads team room" on public.messages
  for select to authenticated using (recipient_id is null);

-- DMs: sender or recipient can read
create policy "Users read their DMs" on public.messages
  for select to authenticated
  using (recipient_id is not null and (sender_id = auth.uid() or recipient_id = auth.uid()));

-- Send: must be self
create policy "Users send as themselves" on public.messages
  for insert to authenticated with check (sender_id = auth.uid());

-- Delete own
create policy "Users delete own messages" on public.messages
  for delete to authenticated using (sender_id = auth.uid());

-- Realtime
alter publication supabase_realtime add table public.messages;
alter table public.messages replica identity full;
