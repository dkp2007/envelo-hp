-- ============================================================
-- MIGRATION 019: Fix RLS with proper UUID casting
-- ============================================================

-- Drop ALL existing policies on affected tables
DO $$ BEGIN
  -- Transactions
  DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_select_policy" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_insert_policy" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_update_policy" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_delete_policy" ON public.transactions;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Enable read access for users based on user_id" ON public.transactions;
  DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.transactions;
  DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.transactions;
  DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.transactions;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Categories
  DROP POLICY IF EXISTS "Users can view own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can insert own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can update own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own categories" ON public.categories;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Savings goals
  DROP POLICY IF EXISTS "Users can view own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Users can insert own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Users can update own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Users can delete own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own savings_goals" ON public.savings_goals;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Budgets
  DROP POLICY IF EXISTS "Users can view own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Users can insert own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Users can update own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Users can delete own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own budgets" ON public.budgets;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Notifications
  DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
  DROP POLICY IF EXISTS "Users can insert own notifications" ON public.notifications;
  DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
  DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Profiles
  DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own profile" ON public.profiles;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Financial plans
  DROP POLICY IF EXISTS "Users can view own plans" ON public.financial_plans;
  DROP POLICY IF EXISTS "Users can insert own plans" ON public.financial_plans;
  DROP POLICY IF EXISTS "Users can delete own plans" ON public.financial_plans;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Stress test results
  DROP POLICY IF EXISTS "Users can view own stress tests" ON public.stress_test_results;
  DROP POLICY IF EXISTS "Users can insert own stress tests" ON public.stress_test_results;
  DROP POLICY IF EXISTS "Users can delete own stress tests" ON public.stress_test_results;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- User settings
  DROP POLICY IF EXISTS "Users can view own settings" ON public.user_settings;
  DROP POLICY IF EXISTS "Users can upsert own settings" ON public.user_settings;
  DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  -- Contact messages
  DROP POLICY IF EXISTS "Anyone can insert contact messages" ON public.contact_messages;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Ensure RLS is enabled on all tables
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stress_test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;

-- Create universal CRUD policies using auth.uid() with text cast
-- This handles any type mismatch between auth.uid() and user_id columns

-- TRANSACTIONS
CREATE POLICY "tx_sel" ON public.transactions FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "tx_ins" ON public.transactions FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "tx_upd" ON public.transactions FOR UPDATE USING (auth.uid()::text = user_id::text);
CREATE POLICY "tx_del" ON public.transactions FOR DELETE USING (auth.uid()::text = user_id::text);

-- CATEGORIES
CREATE POLICY "cat_sel" ON public.categories FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "cat_ins" ON public.categories FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "cat_upd" ON public.categories FOR UPDATE USING (auth.uid()::text = user_id::text);
CREATE POLICY "cat_del" ON public.categories FOR DELETE USING (auth.uid()::text = user_id::text);

-- SAVINGS GOALS
CREATE POLICY "sg_sel" ON public.savings_goals FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "sg_ins" ON public.savings_goals FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "sg_upd" ON public.savings_goals FOR UPDATE USING (auth.uid()::text = user_id::text);
CREATE POLICY "sg_del" ON public.savings_goals FOR DELETE USING (auth.uid()::text = user_id::text);

-- BUDGETS
CREATE POLICY "bud_sel" ON public.budgets FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "bud_ins" ON public.budgets FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "bud_upd" ON public.budgets FOR UPDATE USING (auth.uid()::text = user_id::text);
CREATE POLICY "bud_del" ON public.budgets FOR DELETE USING (auth.uid()::text = user_id::text);

-- NOTIFICATIONS
CREATE POLICY "noti_sel" ON public.notifications FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "noti_ins" ON public.notifications FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "noti_upd" ON public.notifications FOR UPDATE USING (auth.uid()::text = user_id::text);
CREATE POLICY "noti_del" ON public.notifications FOR DELETE USING (auth.uid()::text = user_id::text);

-- PROFILES
CREATE POLICY "prof_sel" ON public.profiles FOR SELECT USING (auth.uid()::text = id::text);
CREATE POLICY "prof_ins" ON public.profiles FOR INSERT WITH CHECK (auth.uid()::text = id::text);
CREATE POLICY "prof_upd" ON public.profiles FOR UPDATE USING (auth.uid()::text = id::text);

-- FINANCIAL PLANS
CREATE POLICY "fp_sel" ON public.financial_plans FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "fp_ins" ON public.financial_plans FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "fp_del" ON public.financial_plans FOR DELETE USING (auth.uid()::text = user_id::text);

-- STRESS TEST RESULTS
CREATE POLICY "st_sel" ON public.stress_test_results FOR SELECT USING (auth.uid()::text = user_id::text);
CREATE POLICY "st_ins" ON public.stress_test_results FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
CREATE POLICY "st_del" ON public.stress_test_results FOR DELETE USING (auth.uid()::text = user_id::text);

-- USER SETTINGS
CREATE POLICY "us_sel" ON public.user_settings FOR SELECT USING (auth.uid()::text = id::text);
CREATE POLICY "us_ins" ON public.user_settings FOR INSERT WITH CHECK (auth.uid()::text = id::text);
CREATE POLICY "us_upd" ON public.user_settings FOR UPDATE USING (auth.uid()::text = id::text);

-- CONTACT MESSAGES (anyone can insert)
CREATE POLICY "cm_ins" ON public.contact_messages FOR INSERT WITH CHECK (true);

-- GRANT permissions to authenticated role
GRANT SELECT, INSERT, UPDATE, DELETE ON public.transactions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.savings_goals TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.budgets TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.financial_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.stress_test_results TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_settings TO authenticated;
GRANT INSERT ON public.contact_messages TO authenticated;

-- Also grant to service_role for admin operations
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
