-- ============================================================
-- CATCH-UP MIGRATION: Fully idempotent
-- Handles any existing table state — adds missing columns,
-- creates missing tables, enables RLS, creates policies
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. CATEGORIES TABLE: create or fix
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  name text not null,
  icon text default '📦',
  color text default '#202124',
  parent_id uuid references public.categories(id) on delete cascade,
  type text not null default 'expense' check (type in ('income', 'expense')),
  created_at timestamp with time zone default now() not null
);

-- Add missing columns to existing categories table
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS parent_id uuid references public.categories(id) on delete cascade;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS type text not null default 'expense';
DO $$ BEGIN
  ALTER TABLE public.categories ADD CONSTRAINT categories_type_check CHECK (type in ('income', 'expense'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS icon text default '📦';
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS color text default '#202124';

-- ────────────────────────────────────────────────────────────
-- 2. BUDGETS TABLE: create or fix
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.budgets (
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

-- ────────────────────────────────────────────────────────────
-- 3. TRANSACTIONS TABLE: create or fix
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transactions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  amount numeric(12, 2) not null,
  type text not null check (type in ('income', 'expense')),
  date date default current_date not null,
  notes text,
  bill_url text,
  bill_path text,
  created_at timestamp with time zone default now() not null
);

ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS category_id uuid references public.categories(id) on delete set null;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS name text not null default 'unnamed';
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS amount numeric(12, 2) not null default 0;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS type text not null default 'expense';
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS date date default current_date;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS bill_url text;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS bill_path text;

-- ────────────────────────────────────────────────────────────
-- 4. SAVINGS_GOALS TABLE: create or fix
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.savings_goals (
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

-- ────────────────────────────────────────────────────────────
-- 5. PROFILES TABLE: create or fix
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text,
  avatar_url text,
  plan text default 'free' check (plan in ('free', 'premium')),
  created_at timestamp with time zone default now() not null
);

-- ────────────────────────────────────────────────────────────
-- 6. INDEXES (all IF NOT EXISTS)
-- ────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_parent ON public.categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_type ON public.categories(type);
CREATE INDEX IF NOT EXISTS idx_budgets_user ON public.budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_month ON public.budgets(month);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(date desc);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_savings_goals_user ON public.savings_goals(user_id);

-- ────────────────────────────────────────────────────────────
-- 7. ENABLE RLS ON ALL TABLES
-- ────────────────────────────────────────────────────────────
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ────────────────────────────────────────────────────────────
-- 8. RLS POLICIES (safe to re-create)
-- ────────────────────────────────────────────────────────────

-- Categories
DO $$ BEGIN CREATE POLICY "Users can view own categories" ON public.categories FOR SELECT USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can insert own categories" ON public.categories FOR INSERT WITH CHECK (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update own categories" ON public.categories FOR UPDATE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete own categories" ON public.categories FOR DELETE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Budgets
DO $$ BEGIN CREATE POLICY "Users can view own budgets" ON public.budgets FOR SELECT USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can insert own budgets" ON public.budgets FOR INSERT WITH CHECK (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update own budgets" ON public.budgets FOR UPDATE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete own budgets" ON public.budgets FOR DELETE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Transactions
DO $$ BEGIN CREATE POLICY "Users can view own transactions" ON public.transactions FOR SELECT USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can insert own transactions" ON public.transactions FOR INSERT WITH CHECK (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update own transactions" ON public.transactions FOR UPDATE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete own transactions" ON public.transactions FOR DELETE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Savings goals
DO $$ BEGIN CREATE POLICY "Users can view own savings goals" ON public.savings_goals FOR SELECT USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can insert own savings goals" ON public.savings_goals FOR INSERT WITH CHECK (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update own savings goals" ON public.savings_goals FOR UPDATE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete own savings goals" ON public.savings_goals FOR DELETE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Profiles
DO $$ BEGIN CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ────────────────────────────────────────────────────────────
-- 9. STORAGE: bills bucket + policies
-- ────────────────────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('bills', 'bills', false, 10485760, ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
ON CONFLICT (id) DO NOTHING;

DO $$ BEGIN DROP POLICY IF EXISTS "Users can upload own bills" ON storage.objects; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "Users can view own bills" ON storage.objects; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "Users can delete own bills" ON storage.objects; EXCEPTION WHEN others THEN NULL; END $$;
DO $$ BEGIN DROP POLICY IF EXISTS "Users can update own bills" ON storage.objects; EXCEPTION WHEN others THEN NULL; END $$;

CREATE POLICY "Users can upload own bills"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'bills' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can view own bills"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'bills' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can delete own bills"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'bills' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Users can update own bills"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'bills' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ────────────────────────────────────────────────────────────
-- 10. SEED: income categories (only for users who have none)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.seed_income_categories()
RETURNS void AS $$
DECLARE
  v_user_id uuid;
  v_salary_id uuid;
  v_freelance_id uuid;
  v_other_id uuid;
BEGIN
  v_user_id := auth.uid();

  IF EXISTS (SELECT 1 FROM public.categories WHERE user_id = v_user_id AND type = 'income') THEN
    RETURN;
  END IF;

  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Salary', '💼', '#2e7d32', 'income')
  RETURNING id INTO v_salary_id;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type)
  VALUES
    (v_user_id, 'Base Salary', '💰', '#2e7d32', v_salary_id, 'income'),
    (v_user_id, 'Bonus', '🎁', '#388e3c', v_salary_id, 'income'),
    (v_user_id, 'Overtime', '⏰', '#43a047', v_salary_id, 'income');

  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Freelance', '💻', '#4285F4', 'income')
  RETURNING id INTO v_freelance_id;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type)
  VALUES
    (v_user_id, 'Projects', '📋', '#4285F4', v_freelance_id, 'income'),
    (v_user_id, 'Consulting', '🤝', '#5c9aff', v_freelance_id, 'income'),
    (v_user_id, 'Commission', '📊', '#79abff', v_freelance_id, 'income');

  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Other Income', '📦', '#757575', 'income')
  RETURNING id INTO v_other_id;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type)
  VALUES
    (v_user_id, 'Gifts Received', '🎉', '#9c27b0', v_other_id, 'income'),
    (v_user_id, 'Refunds', '↩️', '#ff9800', v_other_id, 'income'),
    (v_user_id, 'Interest', '🏦', '#2196f3', v_other_id, 'income'),
    (v_user_id, 'Rental Income', '🏠', '#795548', v_other_id, 'income');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
