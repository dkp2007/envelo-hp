create table public.user_settings (
  id uuid references auth.users(id) on delete cascade primary key,
  phone text,
  country text default 'India',
  currency text default '₹ INR',
  language text default 'English',
  timezone text default 'Asia/Kolkata',
  date_format text default 'DD/MM/YYYY',
  email_notifications boolean default true,
  budget_alerts boolean default true,
  savings_reminders boolean default false,
  weekly_report boolean default true,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

alter table public.user_settings enable row level security;

create policy "Users can view own settings"
  on public.user_settings for select
  using (auth.uid() = id);

create policy "Users can insert own settings"
  on public.user_settings for insert
  with check (auth.uid() = id);

create policy "Users can update own settings"
  on public.user_settings for update
  using (auth.uid() = id);

create policy "Users can delete own settings"
  on public.user_settings for delete
  using (auth.uid() = id);

create or replace function public.handle_new_user_settings()
returns trigger as $$
begin
  insert into public.user_settings (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created_settings
  after insert on auth.users
  for each row execute function public.handle_new_user_settings();
