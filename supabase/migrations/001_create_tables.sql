create table public.categories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  icon text default '📦',
  color text default '#202124',
  parent_id uuid references public.categories(id) on delete cascade,
  created_at timestamp with time zone default now() not null
);

create table public.budgets (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete cascade not null,
  amount numeric(12, 2) not null default 0,
  spent numeric(12, 2) not null default 0,
  month date not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  unique(category_id, month)
);

create table public.transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  amount numeric(12, 2) not null,
  type text not null check (type in ('income', 'expense')),
  date date default current_date not null,
  notes text,
  created_at timestamp with time zone default now() not null
);

create table public.savings_goals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  target numeric(12, 2) not null,
  current numeric(12, 2) not null default 0,
  icon text default '🎯',
  deadline date,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text,
  avatar_url text,
  plan text default 'free' check (plan in ('free', 'premium')),
  created_at timestamp with time zone default now() not null
);

create index idx_categories_user on public.categories(user_id);
create index idx_categories_parent on public.categories(parent_id);
create index idx_budgets_user on public.budgets(user_id);
create index idx_budgets_month on public.budgets(month);
create index idx_transactions_user on public.transactions(user_id);
create index idx_transactions_date on public.transactions(date desc);
create index idx_transactions_category on public.transactions(category_id);
create index idx_savings_goals_user on public.savings_goals(user_id);
