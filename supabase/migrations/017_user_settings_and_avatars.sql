-- ============================================================
-- MIGRATION 017: Fix user_settings + add avatars bucket
-- ============================================================

-- User settings table (safe create)
create table if not exists public.user_settings (
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
  updated_at timestamptz default now()
);

-- Add missing columns if table already existed
do $$ begin
  alter table public.user_settings add column if not exists phone text;
  alter table public.user_settings add column if not exists country text default 'India';
  alter table public.user_settings add column if not exists currency text default '₹ INR';
  alter table public.user_settings add column if not exists language text default 'English';
  alter table public.user_settings add column if not exists timezone text default 'Asia/Kolkata';
  alter table public.user_settings add column if not exists date_format text default 'DD/MM/YYYY';
  alter table public.user_settings add column if not exists email_notifications boolean default true;
  alter table public.user_settings add column if not exists budget_alerts boolean default true;
  alter table public.user_settings add column if not exists savings_reminders boolean default false;
  alter table public.user_settings add column if not exists weekly_report boolean default true;
  alter table public.user_settings add column if not exists updated_at timestamptz default now();
exception when others then null;
end $$;

-- RLS (safe create with exception handling)
do $$ begin
  alter table public.user_settings enable row level security;
exception when others then null;
end $$;

do $$ begin
  create policy "Users can view own settings"
    on public.user_settings for select
    using (auth.uid() = id);
exception when duplicate_object then null;
end $$;

do $$ begin
  create policy "Users can upsert own settings"
    on public.user_settings for insert
    with check (auth.uid() = id);
exception when duplicate_object then null;
end $$;

do $$ begin
  create policy "Users can update own settings"
    on public.user_settings for update
    using (auth.uid() = id);
exception when duplicate_object then null;
end $$;

-- Avatars storage bucket
insert into storage.buckets (id, name, public)
  values ('avatars', 'avatars', true)
  on conflict (id) do nothing;

-- Storage policies (safe create)
do $$ begin
  create policy "Avatar images are publicly accessible"
    on storage.objects for select
    using (bucket_id = 'avatars');
exception when duplicate_object then null;
end $$;

do $$ begin
  create policy "Users can upload avatar"
    on storage.objects for insert
    with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
exception when duplicate_object then null;
end $$;

do $$ begin
  create policy "Users can update own avatar"
    on storage.objects for update
    using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
exception when duplicate_object then null;
end $$;

do $$ begin
  create policy "Users can delete own avatar"
    on storage.objects for delete
    using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);
exception when duplicate_object then null;
end $$;
