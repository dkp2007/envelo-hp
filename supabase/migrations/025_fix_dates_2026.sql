-- ============================================================
-- MIGRATION 025: Fix dates to 2026 (current year)
-- ============================================================

-- Update all transaction dates from 2025 to 2026
UPDATE public.transactions SET date = date + interval '1 year' WHERE date < '2026-01-01';

-- Update budget months from 2025 to 2026
UPDATE public.budgets SET month = month + interval '1 year' WHERE month < '2026-01-01';

-- Update savings goal deadlines
UPDATE public.savings_goals SET deadline = deadline + interval '1 year' WHERE deadline < '2026-01-01';
