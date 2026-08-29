create table public.contact_messages (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  email text not null,
  subject text not null check (subject in ('account', 'billing', 'feature', 'bug', 'other')),
  message text not null,
  status text default 'new' check (status in ('new', 'read', 'replied', 'archived')),
  created_at timestamp with time zone default now() not null
);

alter table public.contact_messages enable row level security;

create policy "Users can submit messages"
  on public.contact_messages for insert
  with check (auth.uid() = user_id or user_id is null);

create policy "Users can view own messages"
  on public.contact_messages for select
  using (auth.uid() = user_id);

create index idx_contact_messages_user on public.contact_messages(user_id);
create index idx_contact_messages_created on public.contact_messages(created_at desc);
