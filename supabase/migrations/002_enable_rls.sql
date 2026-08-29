alter table public.envelopes enable row level security;
alter table public.transactions enable row level security;
alter table public.savings_goals enable row level security;
alter table public.profiles enable row level security;

create policy "Users can view own envelopes"
  on public.envelopes for select
  using (auth.uid() = user_id);

create policy "Users can insert own envelopes"
  on public.envelopes for insert
  with check (auth.uid() = user_id);

create policy "Users can update own envelopes"
  on public.envelopes for update
  using (auth.uid() = user_id);

create policy "Users can delete own envelopes"
  on public.envelopes for delete
  using (auth.uid() = user_id);

create policy "Users can view own transactions"
  on public.transactions for select
  using (auth.uid() = user_id);

create policy "Users can insert own transactions"
  on public.transactions for insert
  with check (auth.uid() = user_id);

create policy "Users can update own transactions"
  on public.transactions for update
  using (auth.uid() = user_id);

create policy "Users can delete own transactions"
  on public.transactions for delete
  using (auth.uid() = user_id);

create policy "Users can view own savings goals"
  on public.savings_goals for select
  using (auth.uid() = user_id);

create policy "Users can insert own savings goals"
  on public.savings_goals for insert
  with check (auth.uid() = user_id);

create policy "Users can update own savings goals"
  on public.savings_goals for update
  using (auth.uid() = user_id);

create policy "Users can delete own savings goals"
  on public.savings_goals for delete
  using (auth.uid() = user_id);

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, avatar_url)
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url'
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
