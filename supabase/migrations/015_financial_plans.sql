-- ============================================================
-- MIGRATION 015: Store AI-generated financial plans
-- ============================================================

create table if not exists public.financial_plans (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  created_at timestamptz default now() not null,

  -- Input data
  monthly_income numeric,
  fixed_expenses numeric,
  variable_expenses numeric,
  savings_goal_name text,
  savings_goal_amount numeric,
  savings_goal_timeline text,
  risk_tolerance text default 'moderate',
  priorities text[] default '{}',

  -- Generated plan (structured JSON)
  plan_data jsonb not null,

  -- Quick summary for dashboard
  summary_title text,
  summary_highlights jsonb
);

alter table public.financial_plans enable row level security;

-- RLS policies
create policy "Users can view own plans"
  on public.financial_plans for select
  using (auth.uid() = user_id);

create policy "Users can insert own plans"
  on public.financial_plans for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own plans"
  on public.financial_plans for delete
  using (auth.uid() = user_id);

-- Index
create index if not exists idx_financial_plans_user on public.financial_plans(user_id, created_at desc);
