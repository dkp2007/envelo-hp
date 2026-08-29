-- ============================================================
-- MIGRATION 018: Fix transactions RLS policies
-- ============================================================

-- Drop existing policies and recreate them safely
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_select_policy" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_insert_policy" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_update_policy" ON public.transactions;
  DROP POLICY IF EXISTS "transactions_delete_policy" ON public.transactions;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Create fresh policies
CREATE POLICY "Users can view own transactions"
  ON public.transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON public.transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
  ON public.transactions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
  ON public.transactions FOR DELETE
  USING (auth.uid() = user_id);

-- Also fix categories RLS
DO $$ BEGIN
  DROP POLICY IF EXISTS "Users can view own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can insert own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can update own categories" ON public.categories;
  DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

CREATE POLICY "Users can view own categories"
  ON public.categories FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories"
  ON public.categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories"
  ON public.categories FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories"
  ON public.categories FOR DELETE
  USING (auth.uid() = user_id);

-- Ensure RLS is enabled
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
