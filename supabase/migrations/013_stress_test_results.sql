-- ============================================================
-- MIGRATION 013: Stress test results table
-- ============================================================

CREATE TABLE IF NOT EXISTS public.stress_test_results (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  monthly_income numeric(12,2) not null,
  monthly_expenses numeric(12,2) not null,
  current_savings numeric(12,2) not null,
  score integer not null,
  total_scenarios integer not null,
  passed_scenarios integer not null,
  scenario_results jsonb not null,
  ai_analysis text,
  created_at timestamp with time zone default now() not null
);

CREATE INDEX IF NOT EXISTS idx_stress_test_user ON public.stress_test_results(user_id);
CREATE INDEX IF NOT EXISTS idx_stress_test_date ON public.stress_test_results(created_at desc);

ALTER TABLE public.stress_test_results ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN CREATE POLICY "Users can view own stress tests" ON public.stress_test_results FOR SELECT USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can insert own stress tests" ON public.stress_test_results FOR INSERT WITH CHECK (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN CREATE POLICY "Users can delete own stress tests" ON public.stress_test_results FOR DELETE USING (auth.uid() = user_id); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
