-- ============================================================
-- MIGRATION 020: Grant permissions to authenticated role
-- ============================================================

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
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
