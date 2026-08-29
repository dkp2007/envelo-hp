-- ============================================================
-- MIGRATION 022: Fix RLS with direct UUID comparison
-- ============================================================

-- Drop all policies from migration 019
DO $$ BEGIN
  DROP POLICY IF EXISTS "tx_sel" ON public.transactions;
  DROP POLICY IF EXISTS "tx_ins" ON public.transactions;
  DROP POLICY IF EXISTS "tx_upd" ON public.transactions;
  DROP POLICY IF EXISTS "tx_del" ON public.transactions;
  DROP POLICY IF EXISTS "cat_sel" ON public.categories;
  DROP POLICY IF EXISTS "cat_ins" ON public.categories;
  DROP POLICY IF EXISTS "cat_upd" ON public.categories;
  DROP POLICY IF EXISTS "cat_del" ON public.categories;
  DROP POLICY IF EXISTS "sg_sel" ON public.savings_goals;
  DROP POLICY IF EXISTS "sg_ins" ON public.savings_goals;
  DROP POLICY IF EXISTS "sg_upd" ON public.savings_goals;
  DROP POLICY IF EXISTS "sg_del" ON public.savings_goals;
  DROP POLICY IF EXISTS "bud_sel" ON public.budgets;
  DROP POLICY IF EXISTS "bud_ins" ON public.budgets;
  DROP POLICY IF EXISTS "bud_upd" ON public.budgets;
  DROP POLICY IF EXISTS "bud_del" ON public.budgets;
  DROP POLICY IF EXISTS "noti_sel" ON public.notifications;
  DROP POLICY IF EXISTS "noti_ins" ON public.notifications;
  DROP POLICY IF EXISTS "noti_upd" ON public.notifications;
  DROP POLICY IF EXISTS "noti_del" ON public.notifications;
  DROP POLICY IF EXISTS "prof_sel" ON public.profiles;
  DROP POLICY IF EXISTS "prof_ins" ON public.profiles;
  DROP POLICY IF EXISTS "prof_upd" ON public.profiles;
  DROP POLICY IF EXISTS "fp_sel" ON public.financial_plans;
  DROP POLICY IF EXISTS "fp_ins" ON public.financial_plans;
  DROP POLICY IF EXISTS "fp_del" ON public.financial_plans;
  DROP POLICY IF EXISTS "st_sel" ON public.stress_test_results;
  DROP POLICY IF EXISTS "st_ins" ON public.stress_test_results;
  DROP POLICY IF EXISTS "st_del" ON public.stress_test_results;
  DROP POLICY IF EXISTS "us_sel" ON public.user_settings;
  DROP POLICY IF EXISTS "us_ins" ON public.user_settings;
  DROP POLICY IF EXISTS "us_upd" ON public.user_settings;
  DROP POLICY IF EXISTS "cm_ins" ON public.contact_messages;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Also drop any old named policies that might conflict
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can view own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can insert own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can update own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can view own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Users can insert own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Users can update own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Users can delete own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Users can view own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Users can insert own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Users can update own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Users can delete own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own categories" ON public.categories;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own savings_goals" ON public.savings_goals;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own budgets" ON public.budgets;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own notifications" ON public.notifications;
  DROP POLICY IF EXISTS "Allow authenticated users to manage own profile" ON public.profiles;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Create policies with DIRECT UUID comparison (no text cast)
-- TRANSACTIONS
CREATE POLICY "tx_all" ON public.transactions
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- CATEGORIES
CREATE POLICY "cat_all" ON public.categories
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- SAVINGS GOALS
CREATE POLICY "sg_all" ON public.savings_goals
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- BUDGETS
CREATE POLICY "bud_all" ON public.budgets
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- NOTIFICATIONS
CREATE POLICY "noti_all" ON public.notifications
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- PROFILES (uses id not user_id)
CREATE POLICY "prof_all" ON public.profiles
  FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- FINANCIAL PLANS
CREATE POLICY "fp_all" ON public.financial_plans
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- STRESS TEST RESULTS
CREATE POLICY "st_all" ON public.stress_test_results
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- USER SETTINGS (uses id not user_id)
CREATE POLICY "us_all" ON public.user_settings
  FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- CONTACT MESSAGES (anyone can insert)
CREATE POLICY "cm_ins" ON public.contact_messages
  FOR INSERT
  WITH CHECK (true);
